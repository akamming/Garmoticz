using Toybox.WatchUi as Ui;
import Toybox.Graphics;
import Toybox.Lang;

class MenuTitleDrawable extends Ui.Drawable {
    //! Constructor
    var _title;

    public function initialize(title as String) {
        _title=title;
    }

    public function draw(dc as Dc) as Void {
        var image = Ui.loadResource( Rez.Drawables.Domoticz_Logo);
        dc.drawBitmap(dc.getWidth()/2-30,2,image);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(dc.getWidth()/2,dc.getHeight()/2,Graphics.FONT_MEDIUM,_title,Graphics.TEXT_JUSTIFY_CENTER);

    }
}
