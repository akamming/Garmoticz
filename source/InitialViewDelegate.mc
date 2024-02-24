using Toybox.WatchUi as Ui;

class InitialViewDelegate extends Ui.BehaviorDelegate {
	var _mview;

    function initialize(mview as InitialView) {
		_mview=mview;
        BehaviorDelegate.initialize();
    
    	// Get device capabilities
    	var mySettings=System.getDeviceSettings();
    	isTouchScreen=mySettings.isTouchScreen;
    
    	// normal initialisation
        WatchUi.BehaviorDelegate.initialize();

    }
      
    function onMenu() {
		Log("onMenu called, getting rooms");
		_mview.getrooms();
    	return true;
    }

}

