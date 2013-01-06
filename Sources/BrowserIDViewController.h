// BrowserIDViewController.h

#import <UIKit/UIKit.h>

@class BrowserIDViewController;

@protocol BrowserIDViewControllerDelegate <NSObject>
- (void) browserIDViewControllerDidCancel: (BrowserIDViewController*) browserIDViewController;
- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController didFailWithReason: (NSString*) reason;
@optional
- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController didSucceedWithAssertion: (NSString*) assertion;
- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController didSucceedVerificationWithReceipt: (NSDictionary*) receipt;
- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController didFailVerificationWithError: (NSError*) error;
@end

@interface BrowserIDViewController : UIViewController <UIWebViewDelegate> {
}

@property (nonatomic,strong) IBOutlet UIWebView* webView;

@property (nonatomic,weak) id<BrowserIDViewControllerDelegate> delegate;
@property (nonatomic,strong) NSString* origin;
@property (nonatomic,strong) NSURL* verifier;

/** After a successful login, this property will be set to the email address the user entered. */
@property (nonatomic,strong) NSString* emailAddress;

@end
