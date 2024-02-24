using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;

class InitialView extends Ui.View {
	var width,height;
	var shown=false;
	
    function initialize() {
       View.initialize();
	}

    function HandleCommand (data) {
        Log("Data is "+data);
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
            Log("Starting directly");
            dz.populateRooms(method(:onRoomsPopulated));
	 		shown=true;			
		} else {
            Log("Not starting menu");
        }
	}

    function startRoomsMenu() {
        var menu = new WatchUi.Menu2({:title=>new MenuTitleDrawable("Rooms")});
        for (var i=0;i<dz.roomItems.size();i++){
            menu.addItem(dz.roomItems[i]);
        }
        var delegate = new Menu2InputDelegate();
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function onRoomsPopulated()
    {
        Log("Callback was called");
        startRoomsMenu();
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
                dc.drawText(width/2,height/2,Gfx.FONT_SMALL,"Hit Menu for Menu\nBack to Exit",Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.drawText(width/2,height/2,Gfx.FONT_SMALL,"Hit Back to Exit",Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
            }
        }
	}
}
