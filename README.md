## Introduction

This project contains sources to integrate BrowserID in an iOS application.

## Theory of Operation

### In a fully native application

First, implement the BrowserIDViewControllerDelegate methods:

```
// Called when the users cancelled the BrowserID process by hitting the Cancel button

- (void) browserIDViewControllerDidCancel: (BrowserIDViewController*) browserIDViewController
{
    [browserIDViewController dismissModalViewControllerAnimated: YES];
}

// Called when the user successfully went through the BrowserID dialog. The assertion
// should be verified in your server. Do not call the BrowserID hosted verifier from your application
// as that will allow users to spoof a login.

- (void) browserIDViewController: (BrowserIDViewController*) browserIDViewController 
    didSucceedWithAssertion: (NSString*) assertion;
{
    [browserIDViewController dismissModalViewControllerAnimated: YES];
    // Pass the assertion to your server to verify it
}
```

Then start the BrowserID process by creating a BrowserIDViewController and displaying it.

```
- (void) startBrowserIDWithOrigin: (NSString*) origin
{
    BrowserIDViewController* browserIDViewController = [BrowserIDViewController new];
    if (browserIDViewController != nil)
    {
        browserIDViewController.origin = origin;
        browserIDViewController.delegate = self;
        
        UINavigationController* navigationController = [[UINavigationController alloc]
            initWithRootViewController: browserIDViewController];
        if (navigationController != nil)
        {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                [self presentModalViewController: navigationController animated: YES];
            } else {
                navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentModalViewController: navigationController animated: YES];
            }
        }
    }
}
```
You can also let the BrowserIDViewController call your verifier. Simply set the `verifier` property to the location of your own verifier.

```
    BrowserIDViewController* browserIDViewController = [BrowserIDViewController new];
    if (browserIDViewController != nil)
    {
        browserIDViewController.origin = origin;
        browserIDViewController.delegate = self;
        browserIDViewController.verifier = [NSURL URLWithString: @"https://my.app/verify"];
    }
```

Then instead of the `browserIDViewController:didSucceedWithAssertion:` delegate method, you implement the `browserIDViewController:didSucceedVerificationWithReceipt:` and `browserIDViewController:didFailVerificationWithError` methods.

The `BrowserIDViewController` will call the verifier endpoint with a `POST` method that has the assertion in the the request body. The verify method is expected to return a JSON structure. The parsed JSON will be given to your in the `browserIDViewController:didSucceedVerificationWithReceipt:` delegate method.

The verify method on your server is also a good place to log the user in. For example by setting a cookie or by generating a session id that you pass back.

Here is a very simple example that is written using the Python Bottle web framework:

```
#
# Called by the native application when it wants to verify the BrowserID token. Will
# return 200 and the user's email address in the body if the verification is succesfull,
# 500 if the request failed or 401 Unauthorized if the verification fails.
#

@route('/verify', method='POST')
def verify():
    data = { 'assertion': request.body.read(), 'audience': "http://localhost:8080"}
    post_response = requests.post('https://browserid.org/verify', data = data, timeout = 5)
    if post_response.status_code != 200:
        abort(500, "BrowserID Error")
    else:
        receipt = json.loads(post_response.content)
        if receipt['status'] == 'okay':
            session_id = create_session(receipt['email'])
            response.set_cookie("browserid_demo_session_id", session_id, max_age = 3600)
        return post_response.content
```

### In a native application that wraps a UIWebView

