using Toybox.WatchUi;

class RoomsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;

    function initialize(dz as Domoticz) {
        _dz=dz;
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
  		var id=item.getId();
        Log("Item is "+id);
        if (_dz.roomItems[id].getSubLabel()==null) {
            _dz.roomItems[id].setSubLabel("Item was clicked");
        } else {
            _dz.roomItems[id].setSubLabel(null);
        }
        WatchUi.requestUpdate();
	}

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (fromGlance) {
            exitApplication=true;
            Log("Exitapplication=true");
        } else {
            Log("Exitapplication=false");
        }
    }
    
}	