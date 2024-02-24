using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Application;
using Toybox.System as Sys;


// define functions for debugging on console which is not executed in release version
(:debug) function Log(message) {
	Sys.println(message);
}

(:release) function Log(message) {
	// do nothing
}

var gSettingsChanged = false;
var fromGlance = false;
var isTouchScreen = false;
var exitApplication = false;
var dz;

// Commands sent by delegate handler
enum {
	NEXTITEM,
	PREVIOUSITEM,
	SELECT,
	BACK,
	MENU
}


class GarmoticzApp extends Application.AppBase {
	hidden var mView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }
    

    // onStop() is called when your application is exiting
    function onStop(state) {
    }
    
    // New app settings have been received so trigger a UI update
	function onSettingsChanged() {
		$.gSettingsChanged = true;
	}

    function getGlanceView() {
        return [ new GarmoticzGlanceView() ];
    }    

     // Return the initial view of your application here
    function getInitialView() {
        // create domoticz object.
        dz = new Domoticz();

        // check if started from Glance
        fromGlance=false;
        var sSettings=Sys.getDeviceSettings();
        if(sSettings has :isGlanceModeEnabled) {
            Log("Device has glance capability");
        	fromGlance=sSettings.isGlanceModeEnabled;
        }
        if (fromGlance) {
            Log("FromGlance=true"); 
        } else {
            Log("FromGlance=false");
        }

        /* if (fromGlance) {
            // Old
            Log("Started from Glance");
            mView = new GarmoticzView();
            return [mView, new GarmoticzViewDelegate(mView.method(:HandleCommand))];
        } else {
            // New
            Log("Started without Glance");
            mView = new InitialView();
            return [mView, new InitialViewDelegate()];
        }*/
        // mView = new InitialView();
        // return [mView, new InitialViewDelegate()];
        //use this if you want to allow returning to the menu
    	if(fromGlance) {
            Log("Glance detected: Start directly");
            return [new M2WView(),new M2WDelegate()];
        } else { 
            Log("Glance not detected: show screen");
            return [new M2WView()];
        }
    }
}   

class M2WView extends WatchUi.View {
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
	   		/* var myMenu=new WatchUi.Menu2({:title=>"Items"});
			myMenu.addItem(new WatchUi.MenuItem("item 1","","i1",{}));
			myMenu.addItem(new WatchUi.MenuItem("item 2","","i2",{}));	 		
	 		WatchUi.pushView(myMenu, new M2WMenuDelegate(),WatchUi.SLIDE_IMMEDIATE); */
            dz.populateRooms(method(:onRoomsPopulated));
	 		shown=true;			
		} else {
            Log("Not starting menu");
        }
	}

    function onRoomsPopulated()
    {
        Log("Callback was called");
        var menu = new WatchUi.Menu2({:title=>"My Menu2"});
        for (var i=0;i<dz.roomItems.size();i++){
            menu.addItem(dz.roomItems[i]);
        }
        var delegate = new Menu2InputDelegate();
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
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

class M2WDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    
    	// Get device capabilities
    	var mySettings=System.getDeviceSettings();
    	isTouchScreen=mySettings.isTouchScreen;
    
    	// normal initialisation
        WatchUi.BehaviorDelegate.initialize();

    }
      
    function onMenu() {
	   	var myMenu=new WatchUi.Menu2({:title=>"Items"});
		myMenu.addItem(new WatchUi.MenuItem("item 1","","i1",{}));
		myMenu.addItem(new WatchUi.MenuItem("item 2","","i2",{}));	 		
	 	WatchUi.pushView(myMenu, new M2WMenuDelegate(),WatchUi.SLIDE_IMMEDIATE);	    	
    	return true;
    }

}

class M2WMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
  		var id=item.getId();
  		if(id.equals("i1")) {System.println("item 1");}
  		if(id.equals("i2")) {System.println("item 2");}  		 	  	
	}

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (fromGlance) {
            exitApplication=true;
            Log("Exitapplication=true");
        } else {
            Log("Exitapplication=false");
        }
    }
    
}	