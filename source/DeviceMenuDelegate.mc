using Toybox.WatchUi;
import Toybox.Lang;

class DevicesMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;

    function initialize(dz as Domoticz) {
        _dz=dz;
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
        if (item instanceof DomoticzMenuItem) {
            Log("onSelect called for "+item.getLabel()+", of type "+item.getDeviceType());
            var devicetype=item.getDeviceType();

            if (devicetype==ONOFF) {
                if (item.getSubLabel().equals(WatchUi.loadResource(Rez.Strings.ON))) {
                    _dz.switchOnOffDevice(item.getId(),false);
                    WatchUi.requestUpdate();
                } else {
                    _dz.switchOnOffDevice(item.getId(),true);
                    WatchUi.requestUpdate();
                }
            } else if (devicetype==SCENE) {
                //
            } else {
                Log("on select called, but no action available for device");
            }
        } else {
            Log("Weird instance of menuitem");
        }
	}

}