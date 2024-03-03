using Toybox.WatchUi;
import Toybox.Lang;

class SelectorMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _dz;
    var _id;

    function initialize(dz as Domoticz,id) {
        _dz=dz;
        _id=id;
        Menu2InputDelegate.initialize();
    }
    
    function onSelect(item) {
        if (item.getId() == 0 ) {
            _dz.switchOnOffDevice(_id,false);

        } else {
            var level=item.getId() as Lang.Number;
            _dz.setLevelDevice(_id,level);
        }
        WatchUi.popView(WatchUi.SLIDE_UP);
    }
}

class SelectorActionMenuDelegate extends WatchUi.ActionMenuDelegate {
    var _dz;
    var _id;

    function initialize(dz as Domoticz,id) {
        _dz=dz;
        _id=id;
        ActionMenuDelegate.initialize();
    }
    
    function onSelect(item) {
        if (item.getId() == 0 ) {
            _dz.switchOnOffDevice(_id,false);

        } else {
            var level=item.getId() as Lang.Number;
            _dz.setLevelDevice(_id,level);
        }
        // how to get down again?
    }
}
