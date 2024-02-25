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
        // _dz.deviceItems[currentid].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_LOADING_DEVICES));
        item.setSubLabel(currentid+": "+(item.getIcon() as DomoticzIcon).nextState());
        WatchUi.requestUpdate();
	}

}