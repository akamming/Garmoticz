import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class DomoticzMenuItem extends Toybox.WatchUi.MenuItem {
    // basically normal menu item, but can store DeviceType and selector states
    private var _devicetype;
    private var _levels;

    public function initialize(_label as Lang.String or Lang.Symbol, 
                    _subLabel as Lang.String or Lang.Symbol or { :enabled as Lang.String or Lang.Symbol or Null, :disabled as Lang.String or Lang.Symbol or Null } or Null, 
                    _identifier, 
                    _options as { :alignment as MenuItem.Alignment, :icon as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol } or Null,
                    devicetype as Number,
                    levels as Array) {

        // initialize the extra vars
        _devicetype=devicetype;
        _levels=levels; 
        
        // Call the parent
        WatchUi.MenuItem.initialize(_label,_subLabel,_identifier,_options);
    }
    
    public function getDeviceType() as Number {
        return _devicetype;
    }

    public function setLevels(levels as Array) {
        _levels=levels;
    }

    public function getLevels() {
        return _levels;
    }


}


class DomoticzToggleMenuItem extends Toybox.WatchUi.ToggleMenuItem {
    // basically normal togglemenu item, but can store DeviceType and selector states
    private var _devicetype;
    private var _levels;


    public function initialize(_label as Lang.String or Lang.Symbol, 
                    _subLabel as Lang.String or Lang.Symbol or { :enabled as Lang.String or Lang.Symbol or Null, :disabled as Lang.String or Lang.Symbol or Null } or Null, 
                    _identifier, 
                    _enabled as Lang.Boolean, 
                    _options as { :alignment as MenuItem.Alignment, :icon as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol } or Null,
                    devicetype as Number,
                    levels as Array) {

        Log("domoticiconmenuitem called");

        // initialize the extra vars
        _devicetype=devicetype;
        _levels=levels; 
        
        // Call the parent
        WatchUi.ToggleMenuItem.initialize(_label,_subLabel,_identifier,_enabled,_options);
    }
    
    public function getDeviceType() as Number {
        return _devicetype;
    }

    public function setLevels(levels as Array) {
        _levels=levels;
    }

    public function getLevels() {
        return _levels;
    }

} 


/*
class DomoticzIconMenuItem extends Toybox.WatchUi.IconMenuItem {

    // Basically a normal iconmenuitem, but can store DeviceType;

    private var _devicetype;
    private var _icon;
 
    public function initialize(label as Lang.String or Lang.Symbol, 
                            subLabel as Lang.String or Lang.Symbol or Null, 
                            identifier, 
                            icon as Graphics.BitmapType or WatchUi.Drawable, 
                            options as { :alignment as MenuItem.Alignment } or Null,
                            devicetype as Number) {


        // remember some settings
        _devicetype=devicetype;
        _icon=icon;

        // call parent
        IconMenuItem.initialize(label,subLabel,identifier,icon,options);  
    }

    public function setDeviceType (devicetype as Number) {
        _devicetype=devicetype;
    }

    public function getDeviceType() as Number {
        return _devicetype;
    }
}


//! This is the custom Icon drawable. It fills the icon space with a color
//! to demonstrate its extents. It changes color each time the next state is
//! triggered, which is done when the item is selected in this application.
class DomoticzIcon extends WatchUi.Drawable {
    // This constant data stores the color state list.
    private const _colors = [Graphics.COLOR_RED, Graphics.COLOR_ORANGE, Graphics.COLOR_YELLOW, Graphics.COLOR_GREEN,
                             Graphics.COLOR_BLUE, Graphics.COLOR_PURPLE] as Array<ColorValue>;
    private const _colorStrings = ["Red", "Orange", "Yellow", "Green", "Blue", "Violet"] as Array<String>;
    private var _index as Number;


    private var _DeviceIdx;

    //! Constructor
    public function initialize(DeviceIdx) {
        Drawable.initialize({});
        _DeviceIdx=DeviceIdx;
        _index = 0;
    }

    //! Advance to the next color state for the drawable
    //! @return The new color state
    public function nextState() as String {
        _index++;
        if (_index >= _colors.size()) {
            _index = 0;
        }

        return _colorStrings[_index];
    }

    //! Return the color string for the menu to use as its sublabel
    //! @return The current color
    public function getString() as String {
        return _colorStrings[_index];
    }

    //! Set the color for the current state and use dc.clear() to fill
    //! the drawable area with that color
    //! @param dc Device Context
    public function draw(dc as Dc) as Void {
        var color = _colors[_index];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();
        var image = WatchUi.loadResource( Rez.Drawables.SensorIcon);
        dc.drawBitmap(dc.getWidth()/2-30,dc.getHeight()/2-30,image);

        // dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
        // dc.drawText(0,0, Graphics.FONT_MEDIUM, dc.getWidth()+"\n"+dc.getHeight(), Graphics.TEXT_JUSTIFY_LEFT);
    }
} */