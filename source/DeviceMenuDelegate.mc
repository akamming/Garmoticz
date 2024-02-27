using Toybox.WatchUi;
import Toybox.Lang;

class DevicesMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;

    function initialize(dz as Domoticz) {
        _dz=dz;
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
        Log("onSelect called");
        if (item instanceof DomoticzToggleMenuItem) {
            var devicetype=item.getDeviceType();
            if (devicetype==ONOFF) {
                if (item.getSubLabel().equals(WatchUi.loadResource(Rez.Strings.ON))) {
                    // switch off
                    // item.setEnabled(false);
                    item.setSubLabel(WatchUi.loadResource(Rez.Strings.OFF)); 
                    _dz.switchOnOffDevice(item.getId(),false);
                    WatchUi.requestUpdate();
                } else {
                    // switch on
                    // item.setEnabled(true); 
                    _dz.switchOnOffDevice(item.getId(),true);
                    item.setSubLabel(WatchUi.loadResource(Rez.Strings.ON)); 
                    WatchUi.requestUpdate();
                }
            } else {
                Log("on select called, but no switchable device");
            }
        } else {
            Log("no togglemenuitem");
        }
        // _dz.deviceItems[currentid].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_LOADING_DEVICES));
        // item.setSubLabel(currentid+": "+(item.getIcon() as DomoticzIcon).nextState());
        // WatchUi.requestUpdate();
	}

}