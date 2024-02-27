using Toybox.WatchUi;
using Toybox.Lang;

class RoomsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;
    var currentid;

    function initialize(dz as Domoticz) {
        _dz=dz;
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
  		currentid=item.getId();
        _dz.roomItems[currentid].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_LOADING_DEVICES));
        WatchUi.requestUpdate();
        _dz.populateDevices(method(:onDevicesPopulated),currentid);
	}

    function startDevicesMenu() {
        var menu = new WatchUi.Menu2({:title=>new MenuTitleDrawable("Devices")});
        var ks=_dz.deviceItems.keys()as Lang.Array<Lang.String or Lang.Number>;
        for (var i=0;i<_dz.deviceItems.size();i++){
            var key=ks[i];
            menu.addItem(_dz.deviceItems[key]);
        }
        WatchUi.pushView(menu, new DevicesMenuDelegate(_dz), WatchUi.SLIDE_IMMEDIATE);
    }


    function onDevicesPopulated(status)
    {
        if (status==null) {
            //all ok, start devices menu
            startDevicesMenu();

            // remove loading message for room
            _dz.roomItems[currentid].setSubLabel(null);
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