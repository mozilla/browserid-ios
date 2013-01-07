// BrowserIDViewController.m

#import "BrowserIDViewController.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif

static NSString* const kBrowserIDSignInURL = @"https://login.persona.org/sign_in#NATIVE";

@implementation BrowserIDViewController

@synthesize webView = _webView;
@synthesize delegate = _delegate;
@synthesize origin = _origin;
@synthesize verifier = _verifier;
@synthesize emailAddress = _emailAddress;

- (UINavigationController*) presentModalInController: (UIViewController*)parentController {
	UINavigationController* navController = [[UINavigationController alloc]
													initWithRootViewController: self];
	if (navController == nil)
		return nil;

	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[parentController presentViewController: navController animated: YES completion: nil];
	return navController;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Log In With Persona", @"BrowserID login window title");
		
	UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle: @"Cancel"
		style: UIBarButtonItemStylePlain target: self action: @selector(cancel)];
#if !__has_feature(objc_arc)
	[cancelButton autorelease];
#endif

	self.navigationItem.rightBarButtonItem = cancelButton;

	_webView.delegate = self;

	// Insert the code that will setup and handle the BrowserID callback.

	NSString* injectedCodePath = [[NSBundle mainBundle] pathForResource: @"BrowserIDViewController" ofType: @"js"];
	NSString* injectedCodeTemplate = [NSString stringWithContentsOfFile: injectedCodePath encoding:NSUTF8StringEncoding error: nil];
	NSAssert(injectedCodeTemplate != nil, @"Could not load BrowserIDViewController.js");

	NSString* injectedCode = [NSString stringWithFormat: injectedCodeTemplate, _origin.absoluteString];

	[_webView stringByEvaluatingJavaScriptFromString: injectedCode];
}

- (void) viewWillAppear:(BOOL)animated
{
	[_webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: kBrowserIDSignInURL]]];
}

- (void) viewDidUnload
{
	[super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	} else {
		return YES;
	}
}

#pragma mark -

- (IBAction) cancel
{
	[_webView stopLoading];
	[_delegate browserIDViewControllerDidCancel: self];
}

#pragma mark -

- (void) verifyAssertion: (NSString*) assertion
{
	// POST the assertion to the verification endpoint. Then report back to our delegate about the
	// results.
	
	id verifyCompletionHandler = ^(NSHTTPURLResponse* response, NSData* data, NSError* error)
	{
		if (error) {
			[_delegate browserIDViewController: self didFailVerificationWithError: error];
		} else {
			NSError* decodingError = nil;
			NSDictionary* receipt = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &decodingError];
			if (decodingError) {
				[_delegate browserIDViewController: self didFailVerificationWithError: decodingError];
			} else {
				[_delegate browserIDViewController: self didSucceedVerificationWithReceipt: receipt];
			}
		}
	};
	
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL: self.verifier cachePolicy: NSURLCacheStorageAllowed timeoutInterval: 5.0];
#if !__has_feature(objc_arc)
	[request autorelease];
#endif
	[request setHTTPShouldHandleCookies: YES];
	[request setHTTPMethod: @"POST"];
	[request setHTTPBody: [assertion dataUsingEncoding: NSUTF8StringEncoding]];
	[request setValue: @"text/plain" forHTTPHeaderField: @"content-type"];
	
	[NSURLConnection sendAsynchronousRequest: request queue: [NSOperationQueue mainQueue]
		completionHandler: verifyCompletionHandler];
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL* url = [request URL];
	
	// The JavaScript side (the code injected in viewDidLoad will make callbacks to this native code by requesting
	// a BrowserIDViewController://callbackname/callback?data=foo style URL. So we capture those here and relay
	// them to our delegate.
	
	if ([[[url scheme] lowercaseString] isEqualToString: @"browseridviewcontroller"])
	{
		NSString* message = url.host;
		NSString* param = [[url query] substringFromIndex: [@"data=" length]];
		NSLog(@"MESSAGE '%@', param '%@'", message, param);
		if ([message isEqualToString: @"assertionReady"]) {
			NSRange separator = [param rangeOfString: @"&email="];
			if (separator.length > 0) {
				NSString* email = [param substringFromIndex: NSMaxRange(separator)];
				param = [param substringToIndex: separator.location];
				self.emailAddress = [email stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
			}
			param = [param stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
			if (_verifier) {
				[self verifyAssertion: param];
			} else {
				[_delegate browserIDViewController: self didSucceedWithAssertion: param];
			}
		}

		else if ([message isEqualToString: @"assertionFailure"]) {
			[_delegate browserIDViewController: self didFailWithReason: param];
		}

		else if ([message isEqualToString: @"gotEmail"]) {
			self.emailAddress = param;
		}

		return NO;
	}
	
	// If the user clicked on a link that escapes the browserid dialog, then we open it in Safari
	
	else if ([[[url scheme] lowercaseString] isEqualToString: @"http"] || [[[url scheme] lowercaseString] isEqualToString: @"https"])
	{
		if ([[url absoluteString] isEqualToString: kBrowserIDSignInURL] == NO)
		{
			[[UIApplication sharedApplication] openURL: url];
			return NO;
		}
	}
	
	return YES;
}

@end
