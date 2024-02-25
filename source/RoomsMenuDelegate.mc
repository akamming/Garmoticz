using Toybox.WatchUi;

class RoomsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;
    var currentid;

    function initialize(dz as Domoticz) {
        _dz=dz;
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
  		currentid=item.getId();
        Log("Item is "+currentid);
        _dz.roomItems[currentid].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_LOADING_DEVICES));
        WatchUi.requestUpdate();
        _dz.populateDevices(method(:onDevicesPopulated),currentid);
	}

    function onDevicesPopulated(status)
    {
        Log("ondevicespopulated was called with status "+status);
        if (status==null) {
            //all ok, start devices menu
            // startRoomsMenu();
            _dz.roomItems[currentid].setSubLabel("Loaded");
            WatchUi.requestUpdate();
        } else {
            // show error
            _dz.roomItems[currentid].setSubLabel(status);
            WatchUi.requestUpdate();
        }
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