//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as System;
using Toybox.Timer as Timer;

class GarmoticzViewDelegate extends Ui.BehaviorDelegate {
    var notify;
    var keyTimer;
    var key;
    var LongPressOccurred;
    var isTouchScreen;

    // Handle menu button press
    function onMenu() {
        //
        notify.invoke(MENU);
        return true;
    }
    
    function onBack() {
    	notify.invoke(BACK);
        return true;
    }
    
    function onSwipe(evt) {
        var swipe = evt.getDirection();

        if (swipe == SWIPE_UP) {
            notify.invoke(NEXTITEM);
        } else if (swipe == SWIPE_DOWN) {
            notify.invoke(PREVIOUSITEM);
        } else if (swipe == SWIPE_RIGHT) {
            notify.invoke(MENU);
        } 
        return true;
    }
        
 	function onTap(clickEvent) {
        var Coordinates=clickEvent.getCoordinates();
        var x=Coordinates[0];
        var y=Coordinates[1];
        if (y<System.getDeviceSettings().screenHeight/3) {
        	// click was in upper part of screen
        	notify.invoke(PREVIOUSITEM);
    	} else if (y>System.getDeviceSettings().screenHeight/3*2) {
    		// click was in lower part of screen
    		notify.invoke(NEXTITEM);
		} else {
			// A selection was made
			notify.invoke(SELECT);
		}
        return true;
    }
    
	function onLongPress() {
		LongPressOccurred=true;
		if (key == KEY_ENTER) {
		    notify.invoke(SELECT);
		}
	}
    
    function onKeyPressed(evt) {
		// store the pressed key in global var for Longpress
		key = evt.getKey();
		
		// (re)set boolean to detect longpress when handling the release of the key.
		LongPressOccurred=false;
		
    	// start the timer to detect for longpress
 		keyTimer.start(method(:onLongPress),1000,false);
    	return false;
	
    }    
    
    function onKeyReleased(evt) {
    	// stop the timer!
    	keyTimer.stop();
    	
    	if (LongPressOccurred) {
    		// longpress occurred. Do not handle this key, because it was handled by the timer.
    		
    	} else {    
    		// it is a shortpress, handle normal behaviour
    			
	    	// retrieve the key
	        key = evt.getKey();
	
	        if (key == KEY_ENTER) {
	        	if (isTouchScreen) {
		        	notify.invoke(SELECT);
	        	} else {
		        	notify.invoke(NEXTITEM);
	        	}
	    	} else if (key == KEY_DOWN) {
	        	notify.invoke(NEXTITEM);
	    	} else if (key == KEY_UP) {
	        	notify.invoke(PREVIOUSITEM);
	        } else {
		        return false;
	        }
    	}
    	return false;
    }

    // Set up the callback to the view
    function initialize(handler) {
    
     	// initialize the timer
     	keyTimer=new Timer.Timer();
    
    	// Get device capabilities
    	var mySettings=System.getDeviceSettings();
    	isTouchScreen=mySettings.isTouchScreen;
    
    	// normal initialisation
        Ui.BehaviorDelegate.initialize();
        notify = handler;
    }


}