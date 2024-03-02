using Toybox.WatchUi;
import Toybox.Lang;

class DimmerMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;
    var _id;

    function initialize(dz as Domoticz,id) {
        _dz=dz;
        _id=id;
        Menu2InputDelegate.initialize();
    }
    
    function onSelect(item) {
        Log(item.getId()+" was selected for "+_id);
    }
}
