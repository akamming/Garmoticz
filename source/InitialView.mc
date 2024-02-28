using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Lang;

class InitialView extends Ui.View {
    var _status;
	var width,height;
	var shown=false;
    var dz=new Domoticz();
    var monkeyVersion;

	
    function initialize() {
        // set correct message
        var _monkeyVersion=Toybox.System.getDeviceSettings().monkeyVersion;
        monkeyVersion=_monkeyVersion[0]*100+_MonkeyV
		Log("Monkey Version is "+monkeyVersion);
        if (monkeyVersion[0]<3) {
            _status=Ui.loadResource(Rez.Strings.STATUS_DEVICE_TOO_OLD);
        } else {
            var mySettings=System.getDeviceSettings();
            if (mySettings.isTouchScreen) {
                _status=Ui.loadResource(Rez.Strings.STATUS_TAP_SCREEN);
            } else {
                _status=Ui.loadResource(Rez.Strings.STATUS_PRESS_ENTER);
            }	
        }

       View.initialize();
	}

    function HandleCommand (data) {
        Log("Data is "+data);
    }

    public function getrooms() {
        if (monkeyVersion[0]>2) {
            _status="Retreiving rooms";
            Ui.requestUpdate();
            dz.populateRooms(method(:onRoomsPopulated));
        } else {
            Log("Ignore, device too old");
        }
    }
	
	function onShow() {
		if(!shown && fromGlance) {
            getrooms();
	 		shown=true;			
        }
	}

    public function startRoomsMenu() {
        var menu = new WatchUi.Menu2({:title=>new MenuTitleDrawable("Rooms")});
        var ks=dz.roomItems.keys() as Lang.Array<Lang.String or Lang.Number>;
        for (var i=0;i<dz.roomItems.size();i++){
            var key=ks[i];
            menu.addItem(dz.roomItems[key]);
        }
        WatchUi.pushView(menu, new RoomsMenuDelegate(dz), WatchUi.SLIDE_IMMEDIATE);
    }

    function onRoomsPopulated(status)
    {
        Log("Callback was called with status "+status);
        if (status==null) {
            //all ok, start rooms menu
            startRoomsMenu();

            // when back from rooms menu: reset message on screen to start message 
    		var mySettings=System.getDeviceSettings();
            if (mySettings.isTouchScreen) {
                _status=Ui.loadResource(Rez.Strings.STATUS_TAP_SCREEN);
            } else {
                _status=Ui.loadResource(Rez.Strings.STATUS_PRESS_ENTER);
            }	
            Ui.requestUpdate();
        } else {
            // show error
            _status=status;
            WatchUi.requestUpdate();
        }
    }
	
	function onLayout(dc) {
		width=dc.getWidth();
		height=dc.getHeight();
	}
	
	function onUpdate(dc) {
        if (exitApplication) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
            dc.clear();
            dc.setColor(Gfx.COLOR_BLUE,Gfx.COLOR_TRANSPARENT);
            var dimensions=dc.getTextDimensions(_status, Gfx.FONT_SMALL);
            var font;
            if (dimensions[0]>dc.getWidth()) {
                font=Gfx.FONT_XTINY;
            } else {
                font=Gfx.FONT_SMALL;
            }
            if (monkeyVersion[0]<3) {
                dc.drawText(width/2,height*1/3,font,_status,Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
                dc.drawText(width/2,height*1/2,Gfx.FONT_XTINY,WatchUi.loadResource(Rez.Strings.STATUS_DEVICE_TOO_OLD_2),Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.drawText(width/2,height/2,font,_status,Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
            }
        }
	}
}
