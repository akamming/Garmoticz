using Toybox.WatchUi as Ui;
using Toybox.System;

class InitialView extends Ui.View {

    function HandleCommand (data)
    {
    	// invoke code
    }


    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        // setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
    		// draw the screen. 1st: clear the current screen and set color
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

		
		// load logo
		var image = Ui.loadResource( Rez.Drawables.Domoticz_Logo);
		dc.drawBitmap(dc.getWidth()/2-30,2,image);
		
		var offset=10;
		// var Line2="Garmoticz";
		var Line2=Ui.loadResource(Rez.Strings.AppName);
		var Line2Status;
		
		var mySettings=System.getDeviceSettings();
		if (mySettings.isTouchScreen) {
			Line2Status=Ui.loadResource(Rez.Strings.STATUS_TAP_SCREEN);
		} else {
			Line2Status=Ui.loadResource(Rez.Strings.STATUS_PRESS_ENTER);
		}	
	
    	// two lines
    	if (dc.getTextWidthInPixels(Line2,Graphics.FONT_LARGE)>dc.getWidth()) { // smaller font is bigger than screen
        	if (dc.getTextWidthInPixels(Line2,Graphics.FONT_MEDIUM)>dc.getWidth()) { // on fenix 5 sometimes even smaller font is too big
	        	dc.drawText(dc.getWidth()/2,dc.getHeight()*5/16+offset,Graphics.FONT_XTINY,Line2,Graphics.TEXT_JUSTIFY_CENTER);
        	} else {
	        	dc.drawText(dc.getWidth()/2,dc.getHeight()*5/16+offset,Graphics.FONT_MEDIUM,Line2,Graphics.TEXT_JUSTIFY_CENTER);
        	}
    	} else {
        	dc.drawText(dc.getWidth()/2,dc.getHeight()*5/16+offset,Graphics.FONT_LARGE,Line2,Graphics.TEXT_JUSTIFY_CENTER);
    	}

    	if (dc.getTextWidthInPixels(Line2Status, Graphics.FONT_LARGE)>dc.getWidth()) { // small font if bigger than screen
        	if (dc.getTextWidthInPixels(Line2Status, Graphics.FONT_MEDIUM)>dc.getWidth()) { // for some watches even medium is too big
		        dc.drawText(dc.getWidth()/2,dc.getHeight()*8/16+offset,Graphics.FONT_XTINY,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
	        } else {
		        dc.drawText(dc.getWidth()/2,dc.getHeight()*8/16+offset,Graphics.FONT_MEDIUM,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
	        }
        } else {
	        dc.drawText(dc.getWidth()/2,dc.getHeight()*8/16+offset,Graphics.FONT_LARGE,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
        }
	
    
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
    
    
    
    

}