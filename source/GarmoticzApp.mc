using Toybox.Application;

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
    

     // Return the initial view of your application here
    function getInitialView() {
        mView = new GarmoticzView();
        return [mView, new GarmoticzViewDelegate(mView.method(:HandleCommand))];
    }

}