using Toybox.WatchUi;

class DevicesMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;
    var currentid;

    function initialize(dz as Domoticz) {
        _dz=dz;
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
  		currentid=item.getId();
        Log("Item is "+currentid);
        // _dz.deviceItems[currentid].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_LOADING_DEVICES));
        if (_dz.deviceItems[currentid].getSubLabel()==null) {
            _dz.deviceItems[currentid].setSubLabel("Selected");
        } else {
            _dz.deviceItems[currentid].setSubLabel(null);
        }
        WatchUi.requestUpdate();
	}

}