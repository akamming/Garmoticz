using Toybox.WatchUi as Ui;
import Toybox.Graphics;
import Toybox.Lang;

class MenuTitleDrawable extends Ui.Drawable {
    //! Constructor
    var _title;

    public function initialize(title as String) {
        _title=title;
        Ui.Drawable.initialize({});
    }

    public function draw(dc as Dc) as Void {
        var image = Ui.loadResource( Rez.Drawables.Domoticz_Logo);
        if (dc.getHeight()>90) {
            dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
            dc.clear();
            dc.drawBitmap(dc.getWidth()/2-30,2,image);
            dc.drawText(dc.getWidth()/2,dc.getHeight()/2,Graphics.FONT_MEDIUM,_title,Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
            dc.clear();
            dc.drawText(dc.getWidth()/2,dc.getHeight()/4,Graphics.FONT_MEDIUM,_title,Graphics.TEXT_JUSTIFY_CENTER);
        }

    }
}
