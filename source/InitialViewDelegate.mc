using Toybox.WatchUi as Ui;

class InitialViewDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    
    	// Get device capabilities
    	var mySettings=System.getDeviceSettings();
    	isTouchScreen=mySettings.isTouchScreen;
    
    	// normal initialisation
        WatchUi.BehaviorDelegate.initialize();

    }
      
    function onMenu() {
	   	var myMenu=new WatchUi.Menu2({:title=>"Items"});
		myMenu.addItem(new WatchUi.MenuItem("item 1","","i1",{}));
		myMenu.addItem(new WatchUi.MenuItem("item 2","","i2",{}));	 		
	 	WatchUi.pushView(myMenu, new M2WMenuDelegate(),WatchUi.SLIDE_IMMEDIATE);	    	
    	return true;
    }

}

