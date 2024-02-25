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
		_mview.getrooms();
    	return true;
    }

	function onTap(clickEvent) {
		_mview.getrooms();
    	return true;
    }

	function onSelect() {
		_mview.getrooms();
    	return true;
    }


}

