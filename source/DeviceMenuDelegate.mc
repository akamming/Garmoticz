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
                } else {
                    _dz.switchOnOffDevice(item.getId(),true);
                }
            } if (devicetype==PUSHON) {
                _dz.switchOnOffDevice(item.getId(),true);
            } if (devicetype==PUSHOFF) {
                _dz.switchOnOffDevice(item.getId(),false);
            } else if (devicetype==INVERTEDBLINDS) {
                if (item.getSubLabel().equals(WatchUi.loadResource(Rez.Strings.CLOSED))) {
                    _dz.switchOnOffDevice(item.getId(),true);
                } else {
                    _dz.switchOnOffDevice(item.getId(),false);
                }
            } else if (devicetype==GROUP) {
                if (item.getSubLabel().equals(WatchUi.loadResource(Rez.Strings.ON))) {
                    _dz.switchOnOffGroup(item.getId(),false);
                } else {
                    _dz.switchOnOffGroup(item.getId(),true);
                }
            } else if (devicetype==SCENE) {
                _dz.switchOnOffGroup(item.getId(),true);
            } else {
                Log("on select called, but no action available for device");
            }
            WatchUi.requestUpdate();

        } else {
            Log("Weird instance of menuitem");
        }
	}

}