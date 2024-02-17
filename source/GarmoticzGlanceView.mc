import Toybox.Application.Storage;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;


(:glance)
class GarmoticzGlanceView extends Ui.GlanceView {
	
    function initialize() {
      GlanceView.initialize();
    }
    
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);

        dc.drawText(0, 
                    dc.getHeight()/2, 
                    Graphics.FONT_TINY,
                    "Garmoticz", 
                    Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);    
    }
}