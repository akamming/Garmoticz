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

        // check if started from Glance
        fromGlance=false;
        var sSettings=Sys.getDeviceSettings();
        if(sSettings has :isGlanceModeEnabled) {
        	fromGlance=sSettings.isGlanceModeEnabled;
        }
        var mview=new InitialView();
        return [mview,new InitialViewDelegate(mview)];
    }
}   


