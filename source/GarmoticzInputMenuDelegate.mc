using Toybox.WatchUi;
using Toybox.System;

class GarmoticzMenuInputDelegate extends WatchUi.MenuInputDelegate {
	var notify;
	
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    	if (MenuType==VENBLIND) {
    		if (item==:OPENMENUITEM) {
	    		status = "SendOpenCommand";
    		} else if (item==:CLOSEMENUITEM) {
    			status = "SendCloseCommand";
			} else if (item==STOPMENUITEM) {
				status = "SendStopCommand";
			}
    	} else if(MenuType==SETPOINT) {
    		setpoint = item;
			status = "SendSetpoint";
    	} else if(MenuType==SELECTOR) {
    		dimmerlevel = item;
			status = "SendSelector";
    	} else if(MenuType==DIMMER) {
    		if (item==:zero) { dimmerlevel = 0;	}
			else if (item==:ten) { dimmerlevel = 10; } 
			else if (item==:twenty) { dimmerlevel = 20; }
			else if (item==:thirty) { dimmerlevel = 30; }
			else if (item==:fourty) { dimmerlevel = 40; }
			else if (item==:fifty) { dimmerlevel = 50; }
			else if (item==:sixty) { dimmerlevel = 60; }
			else if (item==:seventy) { dimmerlevel = 70; }
			else if (item==:eightie) { dimmerlevel = 80; }
			else if (item==:ninenty) { dimmerlevel = 90; }
			else { dimmerlevel = 100; }
			status = "SendDimmerValue";
    	} 
    }
}