using Toybox.WatchUi;
using Toybox.System;

class GarmoticzMenuInputDelegate extends WatchUi.MenuInputDelegate {
	var notify;
	
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    	// System.println("OnMenu, item = "+item+", status="+status);
    	if (status.equals("ShowRooms")) {
    		if (item==BACKMENUITEM) {
    			status="ShowRooms";
			} else {
	    		roomcursor=item;
	    		roomidx=RoomsIdx[item];
	    		devicecursor=0;
				RoomsIdx=null;
				RoomsName=null;
				status="Fetching Devices";
			}    		
    		
    	} else if (status.equals("ShowDevices")) {
    		if (item==BACKMENUITEM) {
    			status = "Fetching Rooms";
			} else {
				devicecursor=item;
				deviceidx=DevicesIdx[item];
				devicetype=DevicesType[item];
				status="ShowDevice";
			}
    	} else if (status.equals("ShowDeviceState")) {
    		if (item==OPENMENUITEM) {
	    		status = "SendOpenCommand";
    		} else if (item==CLOSEMENUITEM) {
    			status = "SendCloseCommand";
			} else if (item==STOPMENUITEM) {
				status = "SendStopCommand";
			}
    	}
    	
    }
    
    
}