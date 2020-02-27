using Toybox.WatchUi;
using Toybox.System;

class GarmoticzMenuInputDelegate extends WatchUi.MenuInputDelegate {
	var notify;
	
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    	if (MenuType==VENBLIND) {
    		if (item==OPENMENUITEM) {
	    		status = "SendOpenCommand";
    		} else if (item==CLOSEMENUITEM) {
    			status = "SendCloseCommand";
			} else if (item==STOPMENUITEM) {
				status = "SendStopCommand";
			}
    	} else if(MenuType==SETPOINT) {
    		setpoint = item;
			status = "SendSetpoint";
    	} else if(MenuType==DIMMER) {
    		dimmerlevel = item;
			status = "SendDimmerValue";
    	} 
    }
}