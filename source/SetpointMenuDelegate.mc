using Toybox.WatchUi;
import Toybox.Lang;

class SetpointMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;
    var _id;

    function initialize(dz as Domoticz,id) {
        _dz=dz;
        _id=id;
        Menu2InputDelegate.initialize();
    }
    
    function onSelect(item) {
        _dz.sendSetpoint(_id,item.getId() as Lang.Float);
        WatchUi.popView(WatchUi.SLIDE_UP);
    }
}

