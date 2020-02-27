using Toybox.WatchUi;
using Toybox.System;

class GarmoticzMenuInputDelegate extends WatchUi.MenuInputDelegate {
	var notify;
	
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    	if (status.equals("ShowDeviceState")) {
    		if (item==OPENMENUITEM) {
	    		status = "SendOpenCommand";
    		} else if (item==CLOSEMENUITEM) {
    			status = "SendCloseCommand";
			} else if (item==STOPMENUITEM) {
				status = "SendStopCommand";
			}
    	} else if(status.equals("SendSetPoint")) {
    		setpoint = item;
			updatesetpoint = true;
    	}
    }
}