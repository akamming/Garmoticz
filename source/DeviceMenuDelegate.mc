using Toybox.WatchUi;
import Toybox.Lang;

class DevicesMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;

    function initialize(dz as Domoticz) {
        _dz=dz;
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
        if (item instanceof DomoticzToggleMenuItem) {
            var isenable=item.isEnabled();
            Log("isenabled is "+item.isEnabled());
            var devicetype=item.getDeviceType();
            if (devicetype==ONOFF) {
                if (item.getSubLabel().equals(WatchUi.loadResource(Rez.Strings.ON))) {
                    item.setEnabled(false);
                    item.setSubLabel(WatchUi.loadResource(Rez.Strings.OFF));
                    WatchUi.requestUpdate();
                } else {
                    item.setSubLabel(WatchUi.loadResource(Rez.Strings.ON));
                    item.setEnabled(true);
                    WatchUi.requestUpdate();
                }
            }
        }
        // _dz.deviceItems[currentid].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_LOADING_DEVICES));
        // item.setSubLabel(currentid+": "+(item.getIcon() as DomoticzIcon).nextState());
        // WatchUi.requestUpdate();
	}

}