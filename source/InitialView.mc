using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.Application as App;

class InitialView extends Ui.View {
    hidden var mView;
    var _status;
	var width,height;
	var shown=false;
    var dz=new Domoticz();
    var monkeyVersion as Lang.Number;
    const minMonkeyVersion=320;
    var interfaceToUse;
	
    function initialize() {
        // set correct message
        var _monkeyVersion=Toybox.System.getDeviceSettings().monkeyVersion;
        monkeyVersion=_monkeyVersion[0]*100+_monkeyVersion[1]*10+_monkeyVersion[2];
		Log("Monkey Version is "+monkeyVersion);
        var mySettings=System.getDeviceSettings();
        if (mySettings.isTouchScreen) {
            _status=Ui.loadResource(Rez.Strings.STATUS_TAP_SCREEN);
        } else {
            _status=Ui.loadResource(Rez.Strings.STATUS_PRESS_ENTER);
        }	

        // decide on interface
        interfaceToUse = App.getApp().getProperty("PROP_INTERFACE");
        if (interfaceToUse==2 and monkeyVersion<minMonkeyVersion) {
            // new interface not available on old devices
            _status="ConnectIQ 3.2 required";
            interfaceToUse=1;
        } else if (interfaceToUse==3) {
            // interface set to auto, determine what to use
            if (monkeyVersion>=minMonkeyVersion) {
                // we are on the right connectiq level, use experimental interface
                interfaceToUse=2;
            } else {
                // device too old: use legacy interface
                interfaceToUse=1;
            }
        }

        View.initialize(); 
	}

    function HandleCommand (data) {
        Log("Data is "+data);
    }

    public function getrooms() {
        if (interfaceToUse==2) {
            _status="Retreiving rooms";
            Ui.requestUpdate();
            dz.populateRooms(method(:onRoomsPopulated));
        } else {
            mView=new GarmoticzView();
            Ui.pushView(mView, new GarmoticzViewDelegate(mView.method(:HandleCommand)), Ui.SLIDE_LEFT);
        }
    }
	
	function onShow() {
		if(!shown && fromGlance) {
            getrooms();
	 		shown=true;			
        }
	}

    public function startRoomsMenu() {
        var menu = new WatchUi.Menu2({:title=>new MenuTitleDrawable(WatchUi.loadResource(Rez.Strings.ROOMS))});
        var ks=dz.roomItems.keys() as Lang.Array<Lang.String or Lang.Number>;
        for (var i=0;i<dz.roomItems.size();i++){
            var key=ks[i];
            menu.addItem(dz.roomItems[key]);
        }
        WatchUi.pushView(menu, new RoomsMenuDelegate(dz), WatchUi.SLIDE_IMMEDIATE);
    }

    function onRoomsPopulated(status)
    {
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
            dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_TRANSPARENT);
            // load logo
            var image = Ui.loadResource( Rez.Drawables.Domoticz_Logo);
            dc.drawBitmap(dc.getWidth()/2-30,2,image);

            var font;
            if (dc.getTextWidthInPixels(_status, Gfx.FONT_SMALL)>dc.getWidth()) {
                font=Gfx.FONT_XTINY;
            } else {
                font=Gfx.FONT_SMALL;
            }
            dc.drawText(width/2, height*5/16, Gfx.FONT_MEDIUM, "Garmoticz", Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(width/2,height/2,font,_status,Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
        }
	}
}
