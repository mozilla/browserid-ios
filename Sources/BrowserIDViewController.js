

window.onload = function()
{
	// The origin is setup when this code template is loaded in the native application
	var origin = "%@";
	
	var callbackToCocoa = function(name, value) {
		window.location = "BrowserIDViewController://" + name + "/callback?data=" + value;
	};

	var internalGetCallback = function(assertion) {
		if (assertion) {
			callbackToCocoa("assertionReady", assertion);
		} else {
			// Not sure what to do here. I don't think there is a 'reason'?
			callbackToCocoa("assertionFailure", "");
		}
	};

	var internalSetPersistentCallback = function() {
		BrowserID.internal.get(origin, internalGetCallback, {silent: false})
	};
	
	BrowserID.internal.setPersistent(origin, internalSetPersistentCallback);
};
