using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.Application as App;

class ErrorView extends Ui.View {
    var _message as Lang.String;
	
    function initialize(message as Lang.String) {
        // store message
        _message=message;

        View.initialize(); 
	}
	
	function onUpdate(dc) {
        var width=dc.getWidth();
		var height=dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        dc.clear();
        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_TRANSPARENT);

        // load logo
        var image = Ui.loadResource(Rez.Drawables.Domoticz_Logo);
        dc.drawBitmap(width/2-30,2,image);

        var font;
        if (dc.getTextWidthInPixels(_message, Gfx.FONT_SMALL)>dc.getWidth()) {
            font=Gfx.FONT_XTINY;
        } else {
            font=Gfx.FONT_SMALL;
        }
        // dc.drawText(width/2, height*5/16, Gfx.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.AppName), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width/2,height/2+15,font,_message,Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
	}
}
