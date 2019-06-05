using Toybox.WatchUi as Ui;

class InitialViewDelegate extends Ui.BehaviorDelegate {
	hidden var mView;
	
	
	
	function StartApp()
	{
	    // start garmoticzview
		mView=new GarmoticzView();
	    Ui.pushView(mView, new GarmoticzViewDelegate(mView.method(:HandleCommand)), WatchUi.SLIDE_LEFT);
	}
	
    function onMenu() {
	    StartApp();
	    return true;
 	}
 	
 	function onTap(clickEvent) {
	    StartApp();
        return true;
    }
    
    function onSelect() {
	    StartApp();
        return true;
    }
    
    // Set up the callback to the view
    function initialize() {
    
    	// normal initialisation
        Ui.BehaviorDelegate.initialize();
    }
    
	
}