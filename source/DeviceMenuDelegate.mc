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
                }
                var dimmermenu = new WatchUi.Menu2({:title => new MenuTitleDrawable(item.getLabel()),
                                                    :focus => currentval});
                dimmermenu.addItem(new MenuItem(WatchUi.loadResource(Rez.Strings.OFF),null,0,{}));
                for (var i=10;i<101;i+=10) {
                    dimmermenu.addItem(new MenuItem(i+"%",null,i,{}));
                }
                var delegate=new DimmerMenuDelegate(_dz,item.getId());
                WatchUi.pushView(dimmermenu,delegate,WatchUi.SLIDE_UP);
            } else if (devicetype==SELECTOR) {
                if (WatchUi has :ActionMenu) {
                    var Levels=item.getLevels();
                    var selectorMenu=new WatchUi.ActionMenu({});
                    for (var i=0;i<Levels.size();i++) {
                        // add menu item
                        selectorMenu.addItem(new ActionMenuItem({:label => Levels[i*10]},i*10));
                    }
                    var delegate=new SelectorActionMenuDelegate(_dz,item.getId());
                    WatchUi.showActionMenu(selectorMenu,delegate);
                } else {
                    var Levels=item.getLevels();
                    var currentval=0;
                    for (var i=0;i<Levels.size();i++) {
                        if (Levels[i*10].equals(item.getSubLabel())) {
                            currentval=i*10;
                        }
                    }
                    if (currentval==null) {
                        currentval=0;
                    }
                    var selectorMenu=new WatchUi.Menu2({:title => new MenuTitleDrawable(item.getLabel()),
                                                        :focus => currentval/10});
                    for (var i=0;i<Levels.size();i++) {
                        // add menu item
                        selectorMenu.addItem(new MenuItem(Levels[i*10],null,i*10,{}));
                    }
                    var delegate=new SelectorMenuDelegate(_dz,item.getId());
                    WatchUi.pushView(selectorMenu,delegate,WatchUi.SLIDE_UP);
                }
            } else if (devicetype==SETPOINT) { 
                var currentval=0;
                // make sure currentval is a number round to 0.5
                for (var i=0.0;i<=100;i+=0.5) {
                    if (i<=item.getSubLabel().toFloat()) {
                        currentval=i;
                    }
                }
                // now determine currentfocus
                var currentfocus=20;

                // now setup menu
                var setpointmenu = new WatchUi.Menu2({:title => new MenuTitleDrawable(item.getLabel()),
                                                    :focus => currentfocus});
                for (var i=currentval-10;i<=currentval+10;i+=0.5) {
                    setpointmenu.addItem(new MenuItem(i.format("%3.1f"),null,i,{}));
                }
                var delegate=new SetpointMenuDelegate(_dz,item.getId());

                // and push view
                WatchUi.pushView(setpointmenu,delegate,WatchUi.SLIDE_UP); 
            } else {
                Log("on select called, but no action available for device");
            } 
            WatchUi.requestUpdate();

        } else {
            Log("Weird instance of menuitem");
        }
	}

}