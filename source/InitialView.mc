using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;

class InitialView extends Ui.View {
    var _status;
	var width,height;
	var shown=false;
    var dz=new Domoticz();
	
    function initialize() {
        if (fromGlance) {
            _status="Hit Back to Exit";
        } else {
            _status="Hit Menu for Menu\nBack to Exit";
        }

       View.initialize();
	}

    function HandleCommand (data) {
        Log("Data is "+data);
    }

    public function getrooms() {
        _status="Retreiving rooms";
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
        for (var i=0;i<dz.roomItems.size();i++){
            menu.addItem(dz.roomItems[i]);
        }
        var delegate = new RoomsMenuDelegate();
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function onRoomsPopulated(status)
    {
        _status=status;
        Log("Callback was called with status "+status);
        if (status==null) {
            startRoomsMenu();
            _status="OK";
        } else {
            Log("Callback was called with status "+status);
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
