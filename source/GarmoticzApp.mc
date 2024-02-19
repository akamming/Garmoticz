using Toybox.Application;
using Toybox.System as Sys;

var gSettingsChanged = false;


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
        var fromGlance=false;
        var sSettings=Sys.getDeviceSettings();
        if(sSettings has :isGlanceModeEnabled) {
            Log("Device has glance capability");
        	fromGlance=sSettings.isGlanceModeEnabled;
        }

        if (fromGlance) {
            // Old
            Log("Started from Glance");
            mView = new GarmoticzView();
            return [mView, new GarmoticzViewDelegate(mView.method(:HandleCommand))];
        } else {
            // New
            Log("Started without Glance");
            mView = new InitialView();
            return [mView, new InitialViewDelegate()];
        }
    }
}