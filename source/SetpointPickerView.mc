using Toybox.Application;
using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.System;

class SetpointPickerView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This include
    //! loading resources into memory.
    function onShow() {
        var app = Application.getApp();

        // find and modify the labels based on what is in the object store
        //var string = findDrawableById("string");
        //var date = findDrawableById("date");
        var setpoint = findDrawableById("setpoint");
        var prop = app.getProperty("setpoint");
        if(prop != null) {
            setpoint.setText(prop);
        }
    }

    //! Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

}

class SetpointPickerDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {

    }

    function onKey(evt) {

    }

    function onCancel() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
        var setpoint = values[0]+"."+values[2];
        Application.getApp().setProperty("setpoint", setpoint);
		Application.getApp().setProperty("updatesetpoint", true);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}