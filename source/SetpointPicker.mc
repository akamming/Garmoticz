using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

class SetpointPicker extends WatchUi.Picker {

    function initialize() {

        var title = new WatchUi.Text({:text=>Rez.Strings.TITLE_SETPOINT, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        var factories;
        factories = new [3];

        factories[0] = new NumberFactory(0, 30, 1, {:format=>"%02d"});
        factories[1] = new WatchUi.Text({:text=>".", :font=>Graphics.FONT_MEDIUM, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER, :color=>Graphics.COLOR_WHITE});
        factories[2] = new NumberFactory(0, 9, 1, {:format=>"%1d"});
        var defaults = splitStoredSetpoint(factories.size());
        if(defaults != null) {
            defaults[0] = factories[0].getIndex(defaults[0].toNumber());
            defaults[2] = factories[2].getIndex(defaults[2].toNumber());
        }

        Picker.initialize({:title=>title, :pattern=>factories, :defaults=>defaults});
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    function splitStoredSetpoint(arraySize) {
        var storedValue = Application.getApp().getProperty("setpoint");
        var defaults = null;
        var separatorIndex = 0;

        if(storedValue != null) {
            defaults = new [arraySize];
            // the Drawable does not have a default value
            defaults[1] = null;

            // HH:MIN AM|PM
            separatorIndex = storedValue.find(".");
            if(separatorIndex != null ) {
                defaults[0] = storedValue.substring(0, separatorIndex);
            }
            else {
                defaults = null;
            }
        }

        if(defaults != null) {
            defaults[2] = storedValue.substring(separatorIndex + 1, storedValue.length());
        }

        return defaults;
    }
}