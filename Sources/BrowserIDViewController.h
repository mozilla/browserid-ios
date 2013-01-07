// BrowserIDViewController.h

#import <UIKit/UIKit.h>

@class BrowserIDViewController;

/** Delegate of a BrowserIDViewController. Of the optional methods, didSucceedWithAssertion
    must be implemented unless the controller's 'verifier' property is set, in which case both
    didSucceedVerificationWithReceipt and didFailVerificationWithError must be implemented. */
@protocol BrowserIDViewControllerDelegate <NSObject>

/** Sent if the user presses the Cancel button on the BrowserID window. */
- (void) browserIDViewControllerDidCancel: (BrowserIDViewController*) browserIDViewController;

/** Sent if the authentication process fails. Currently the reason will just be @"". */
- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController
               didFailWithReason: (NSString*) reason;
@optional
/** Sent after authentication was successful. The assertion will be a long opaque string that
    should be sent to the origin site's BrowserID authentication API. */
- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController
         didSucceedWithAssertion: (NSString*) assertion;

/** Sent after authentication and server-side verification are successful, _only_ if the
    controller's 'verifier' property is set to a server-side verifier URL.
    The 'receipt' parameter is the verifier response as decoded from JSON. */
- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController
         didSucceedVerificationWithReceipt: (NSDictionary*) receipt;

/** Sent if server-side verification fails, _only_ if the controller's 'verifier' property is set
    to a server-side verifier URL. */
- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController
    didFailVerificationWithError: (NSError*) error;

@end

@interface BrowserIDViewController : UIViewController <UIWebViewDelegate> {
}

@property (nonatomic,strong) IBOutlet UIWebView* webView;

/** The object that will be informed about success or failure. Required. */
@property (nonatomic,weak) id<BrowserIDViewControllerDelegate> delegate;

/** The URL of the site the user is logging into (i.e. the site you will send the assertion to).
    Required. */
@property (nonatomic,strong) NSURL* origin;

/** An optional URL of a verification service provided by your applicatin's server-side counterpart.
    If this property is set, an assertion will be sent to this URL as the body of a POST request,
    and the response relayed to the delegate via its verification-related methods. */
@property (nonatomic,strong) NSURL* verifier;

/** After a successful login, this property will be set to the email address the user entered. */
@property (nonatomic,strong) NSString* emailAddress;

/** A convenience method that puts the receiver in a UINavigationController and presents it modally
    in the given parent controller. */
- (UINavigationController*) presentModalInController: (UIViewController*)parentController;

@end
