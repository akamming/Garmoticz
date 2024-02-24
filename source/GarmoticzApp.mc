using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Application;
using Toybox.System as Sys;


// define functions for debugging on console which is not executed in release version
(:debug) function Log(message) {
	Sys.println(message);
}

(:release) function Log(message) {
	// do nothing
}

var gSettingsChanged = false;
var fromGlance = false;
var isTouchScreen = false;
var exitApplication = false;
var dz;

// Commands sent by delegate handler
enum {
	NEXTITEM,
	PREVIOUSITEM,
	SELECT,
	BACK,
	MENU
}


class GarmoticzApp extends Application.AppBase {
	hidden var mView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }
    

    // onStop() is called when your application is exiting
    function onStop(state) {
    }
    
    // New app settings have been received so trigger a UI update
	function onSettingsChanged() {
		$.gSettingsChanged = true;
	}

    function getGlanceView() {
        return [ new GarmoticzGlanceView() ];
    }    

     // Return the initial view of your application here
    function getInitialView() {
        // create domoticz object.
        dz = new Domoticz();

        // check if started from Glance
        fromGlance=false;
        var sSettings=Sys.getDeviceSettings();
        if(sSettings has :isGlanceModeEnabled) {
            Log("Device has glance capability");
        	fromGlance=sSettings.isGlanceModeEnabled;
        }
        if (fromGlance) {
            Log("FromGlance=true"); 
        } else {
            Log("FromGlance=false");
        }

        /* if (fromGlance) {
            // Old
            Log("Started from Glance");
            mView = new GarmoticzView();
            return [mView, new GarmoticzViewDelegate(mView.method(:HandleCommand))];
        } else {
            // New
            Log("Started without Glance");
            mView = new InitialView();
            return [mView, new InitialViewDelegate()];
        }*/
        // mView = new InitialView();
        // return [mView, new InitialViewDelegate()];
        //use this if you want to allow returning to the menu
    	if(fromGlance) {
            Log("Glance detected: Start directly");
            return [new InitialView(),new InitialViewDelegate()];
        } else { 
            Log("Glance not detected: show screen");
            return [new InitialView()];
        }
    }
}   


class M2WMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
  		var id=item.getId();
  		if(id.equals("i1")) {System.println("item 1");}
  		if(id.equals("i2")) {System.println("item 2");}  		 	  	
	}

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (fromGlance) {
            exitApplication=true;
            Log("Exitapplication=true");
        } else {
            Log("Exitapplication=false");
        }
    }
    
}	