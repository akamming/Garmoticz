using Toybox.WatchUi;
import Toybox.Lang;

class DevicesMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;

    function initialize(dz as Domoticz) {
        _dz=dz;
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
        if (item instanceof DomoticzMenuItem or item instanceof DomoticzToggleMenuItem) {
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
            } else if (devicetype==DIMMER) { 
                var currentval;
                if (item.getSubLabel().equals(WatchUi.loadResource(Rez.Strings.OFF))) {
                    currentval=0;
                } else if (item.getSubLabel().equals(WatchUi.loadResource(Rez.Strings.ON))) {
                    currentval=10;
                } else {
                    currentval=(item.getSubLabel().substring(0,3).toNumber()+4)/10;
                    Log("currentval of "+item.getSubLabel().substring(0,3)+" is "+currentval);
                }
                var dimmermenu = new WatchUi.Menu2({:title => new MenuTitleDrawable(item.getLabel()),
                                                    :focus => currentval});
                dimmermenu.addItem(new MenuItem(WatchUi.loadResource(Rez.Strings.OFF),null,0,{}));
                for (var i=10;i<101;i+=10) {
                    dimmermenu.addItem(new MenuItem(i+"%",null,i,{}));
                }
                var delegate=new DimmerMenuDelegate(_dz,item.getId());
                WatchUi.pushView(dimmermenu,delegate,WatchUi.SLIDE_UP);
                // }
            } else {
                Log("on select called, but no action available for device");
            } 
            WatchUi.requestUpdate();

        } else {
            Log("Weird instance of menuitem");
        }
	}

}