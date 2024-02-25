using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;

class InitialView extends Ui.View {
    var _status;
	var width,height;
	var shown=false;
    var dz=new Domoticz();
	
    function initialize() {
        // set correct message
        var mySettings=System.getDeviceSettings();
        if (mySettings.isTouchScreen) {
            _status=Ui.loadResource(Rez.Strings.STATUS_TAP_SCREEN);
        } else {
            _status=Ui.loadResource(Rez.Strings.STATUS_PRESS_ENTER);
        }	

       View.initialize();
	}

    function HandleCommand (data) {
        Log("Data is "+data);
    }

    public function getrooms() {
        _status="Retreiving rooms";
        Ui.requestUpdate();
        dz.populateRooms(method(:onRoomsPopulated));
    }
	
	function onShow() {
        if (shown) {
            Log("Shown=true"); 
        } else {
            Log("Shown=false");
        }
        if (fromGlance) {
            Log("fromGlance=true"); 
        } else {
            Log("fromGlance=false");
        }
		if(!shown && fromGlance) {
            getrooms();
	 		shown=true;			
		} else {
            Log("Not starting menu");
        }
	}

    public function startRoomsMenu() {
        var menu = new WatchUi.Menu2({:title=>new MenuTitleDrawable("Rooms")});
        var ks=dz.roomItems.keys();
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
            if(!fromGlance) {
                dc.drawText(width/2,height/2,Gfx.FONT_SMALL,_status,Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.drawText(width/2,height/2,Gfx.FONT_SMALL,_status,Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
            }
        }
	}
}
