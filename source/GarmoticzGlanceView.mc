import Toybox.Application.Storage;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;



(:glance)
class GarmoticzGlanceView extends Ui.GlanceView {
	
    function initialize() {
      GlanceView.initialize();
    }
    
    function onUpdate(dc) {
        // dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        // dc.clear();
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
        // var Text=Ui.loadResource(Rez.Strings.AppName);
        var Text="Garmoticz";
        // Text=App.getApp().getProperty("PROP_ADRESS");
        dc.drawText(0, 
                    dc.getHeight()/2, 
                    Graphics.FONT_TINY,
                    Text, 
                    Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);    
    }
}