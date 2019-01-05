using Toybox.WatchUi;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.StringUtil as Su;
using Toybox.Application as App;
using Toybox.Timer as Timer;

// Commands sent by delegate handler
const NEXTITEM=1;
const PREVIOUSITEM=2;
const SELECT=3;
const BACK=4;
const MENU=5;

class GarmoticzView extends WatchUi.View {
	// Global vars
	var StatusText="";
	var Line1="";
	var Line2="";
	var Line3="";
	var Line2Status="";
	
	var DevicesName;
	var DevicesIdx;
	var DevicesSwitchType;
	var DevicesData;
	var DevicesType;

	var RoomsIdx;
	var RoomsName;

	var roomcursor=0;
	var devicecursor=0;
	var roomidx=0;
	var deviceidx=0;
	var devicetype;
	var status="Fetching Rooms";
	
	// Timer to prevent too many url's when scrolling through devices
	var delayTimer;
	
	// Config (using garmin express)
	var Domoticz_UserName;
	var Domoticz_Password;
	var Domoticz_Protocol;
	var Domoticz_Adress;
	var Domoticz_Port;
	var Domoticz_Roomplan;

	// jsoncommands
	const GETROOMS=1; 
	const GETDEVICES=2;
	const GETDEVICESTATUS=3;
	const SENDONCOMMAND=4;
	const SENDOFFCOMMAND=5;
	const GETSCENESTATUS=6;
	const SWITCHONGROUP=7;
	const SWITCHOFFGROUP=8;

    function initialize() {
    	// Get the configured settings
        retrieveSettings();   
        
        // initializez timer
        delayTimer=new Timer.Timer();
        
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    
    	// Set Height en Width
        
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	
     	// Load the last known vales of the cursor
        var app = Application.getApp();       
        devicecursor = app.getProperty("devicecursor");       
        roomcursor = app.getProperty("roomcursor");       
        roomidx = app.getProperty("roomidx");       
        deviceidx = app.getProperty("deviceidx");       
        devicetype = app.getProperty("devicetype");       
		status=app.getProperty("status");       
		
        // Reset values to readable if they are null       
        if (devicecursor==null) {
       		devicecursor=0; 
        }
        if (deviceidx==null) {
       		deviceidx=0;
        }
		if (roomcursor==null) {
       		roomcursor=0;
   		}
        if (roomidx==null) {
       		roomidx=0;
        }
   		if (status==null) {
   			status="Fetching Rooms";
       }
       
       // set correct state based on previous state
       if (status.equals("ShowDeviceState")) {
       		status="Fetching Devices";
	    	makeWebRequest(GETDEVICES);
       } else {
       		status="Fetching Rooms";
        	makeWebRequest(GETROOMS);
       }       
    }
    
    
   function retrieveSettings() {
	    // Get variables From settings
	    Domoticz_UserName = App.getApp().getProperty("PROP_USERNAME");
		Domoticz_Password= App.getApp().getProperty("PROP_PASSWORD");
		if (App.getApp().getProperty("PROP_PROTOCOL")==0) {
			Domoticz_Protocol="http";
		} else {
			Domoticz_Protocol="https";
		}
		Domoticz_Adress= App.getApp().getProperty("PROP_ADRESS");
		Domoticz_Port= App.getApp().getProperty("PROP_PORT");
	}
	
	    // Handle Command from Delegate view
    function HandleCommand (data)
    {
    	// stop the timer (if new action was done too fast, no update from device will take place)
    	delayTimer.stop();
    	
         if (data==NEXTITEM) {
         	NextItem();
     	} else if (data==PREVIOUSITEM) {
     		PreviousItem();
 		} else if (data==SELECT) {
 			Select();
 		} else if (data==MENU) {
 			ResetApplication();
 		} 
    }
    
    function ResetApplication()
    {
    	// Reset the application
    	status="Fetching Rooms";
    	makeWebRequest(GETROOMS);
    	Ui.requestUpdate();    	
    }

	function NextItem()
	{
		// handle nextitem
		if (status.equals("ShowDeviceState")) {
			devicecursor++;
			if (devicecursor==DevicesIdx.size())
			{ 
				devicecursor=0;
			}
			deviceidx=DevicesIdx[devicecursor];
			devicetype=DevicesType[devicecursor];
			delayTimer.start(method(:getDeviceStatus),500,false);	            	
			Ui.requestUpdate(); 
			
		} else if (status.equals("ShowRooms")) {
			roomcursor++;
			if (roomcursor==RoomsIdx.size())
			{ 
				roomcursor=0;
			}
			roomidx=RoomsIdx[roomcursor];
			Ui.requestUpdate(); 
					
		} 
		
	}
	
	function PreviousItem()
	{
		// handle previous 
		if (status.equals("ShowDeviceState")) {
			devicecursor--;
			if (devicecursor<0) 
			{
				devicecursor=DevicesIdx.size()-1;
			}
			deviceidx=DevicesIdx[devicecursor];
			devicetype=DevicesType[devicecursor];
			delayTimer.start(method(:getDeviceStatus),500,false);	            	
			Ui.requestUpdate();
		} else if (status.equals("ShowRooms")) {
			roomcursor--;
			if (roomcursor<0) 
			{
				roomcursor=RoomsIdx.size()-1;
			}
			roomidx=RoomsIdx[roomcursor];
			Ui.requestUpdate();
		} 
	}
	
	function Select()
	{
		if (status.equals("ShowDeviceState")) {
			if (DevicesSwitchType[devicecursor]!=null) {
				// Device is a switch
				if (DevicesSwitchType[devicecursor].equals("On/Off")) {
					// Device is switchable

			    	// communicate status
			    	status="Sending Command";	

					// handle differently of on and off
					if (DevicesData[devicecursor].equals("On")) {
						DevicesData[devicecursor]="Switching Off";
						makeWebRequest(SENDOFFCOMMAND);
					} else {
						DevicesData[devicecursor]="Switching On";
						makeWebRequest(SENDONCOMMAND);
					}
					
					// update the UI
					Ui.requestUpdate();
				}
			} 
			if (DevicesType[devicecursor].equals("Group")) {
		    	// communicate status
		    	status="Sending Command";	

				// handle differently of on and off
				if (DevicesData[devicecursor].equals("On")) {
					DevicesData[devicecursor]="Switching Off";
					makeWebRequest(SWITCHOFFGROUP);
				} else {
					DevicesData[devicecursor]="Switching On";
					makeWebRequest(SWITCHONGROUP);
				}
				
				// update the UI
				Ui.requestUpdate();

			} 
			if (DevicesType[devicecursor].equals("Scene")) {
		    	// communicate status
		    	status="Sending Command";	

				DevicesData[devicecursor]="Activating Scene";
				makeWebRequest(SWITCHONGROUP);
				
				// update the UI
				Ui.requestUpdate();
			}
		} else if (status.equals("ShowRooms")) {
			devicecursor=0;
			status="Fetching Devices";
			makeWebRequest(GETDEVICES);
			Ui.requestUpdate();
		}
	}
	
	function SetRoomCursor() {
	    // Set the cursor at the saved idx (or leave at 0 if the idx is no longer there)
		roomcursor=0;
		for (var i=0;i<RoomsIdx.size();i++) {
		   if (RoomsIdx[i].equals(roomidx)) {
		   		roomcursor=i;
		   }
		}
		roomidx=RoomsIdx[roomcursor];
	}

	 // Set the cursor at the saved value (or set to 0 if we cannot find it)
	function SetDeviceCursor() {
		devicecursor=0;
		for (var i=0;i<DevicesIdx.size();i++) {
			if (DevicesIdx[i].equals(deviceidx) and DevicesType[i].equals(devicetype)) {
				devicecursor=i;
			}
		}
		deviceidx=DevicesIdx[devicecursor];
		devicetype=DevicesType[devicecursor];
	}


    function makeWebRequest(action) {

		// If settings were change, get new settings before we try again
        if ($.gSettingsChanged) {
			$.gSettingsChanged = false;
			retrieveSettings();
		}
		
		if (Domoticz_Adress==null) {
			status="Error";
			StatusText="Invalid connection settings";
		} else {
			if (Domoticz_Adress.equals("")) {
				status="Error";
				StatusText="Invalid connection settings";
			} else {
		    	//needed vars
		    	var url;
		    	var prefix=Domoticz_Protocol+"://"+Domoticz_Adress+":"+Domoticz_Port+"/json.htm?username="+Su.encodeBase64(Domoticz_UserName)+"&password="+Su.encodeBase64(Domoticz_Password)+"&";
		        
		    	// create url
		    	if (action==GETDEVICES) {
		    		// build url to get the list of decices in the room
			    	url=prefix+"type=command&param=getplandevices&idx="+roomidx; // get roomplan connectiq
		    	}	else if (action==GETDEVICESTATUS) {
		    		// build url to get the status of the current device
		    		url=prefix+"type=devices&rid="+DevicesIdx[devicecursor]; // get device info
		    	}	else if (action==GETSCENESTATUS) {
		    		// build url to get the status of the current scene
		    		url=prefix+"type=scenes"; // get device info
		    	}	else if (action==GETROOMS) {
		    		// build url to get all roomplans
		    		url=prefix+"type=plans&order=Order&used=true"; // get device info
		    	}	else if (action==SENDONCOMMAND) {
		    		// build url to switch on device
		    		url=prefix+"type=command&param=switchlight&idx="+DevicesIdx[devicecursor]+"&switchcmd=On"; // Send on command
		    	}	else if (action==SENDOFFCOMMAND) {
		    		// build url to switch off device
		    		url=prefix+"type=command&param=switchlight&idx="+DevicesIdx[devicecursor]+"&switchcmd=Off"; // Send off command
		    	}	else if (action==SWITCHOFFGROUP) {
		    		// build url to switch off group/scene
		    		url=prefix+"type=command&param=switchscene&idx="+DevicesIdx[devicecursor]+"&switchcmd=Off"; // Send off command
		    	}	else if (action==SWITCHONGROUP) {
		    		// build url to switch on group/scene
		    		url=prefix+"type=command&param=switchscene&idx="+DevicesIdx[devicecursor]+"&switchcmd=On"; // Send off command
		    	} else {
		    		url="unknown url";
		    	}
		
				// Make the request
		        Comm.makeWebRequest(
		            url,
		            {
		            },
		            {
		                "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
		            },
			            method(:onReceive)
			     );
			}
		}
    
    
    }
    
    // Receive the data from the web request
    function onReceive(responseCode, data) 
    {
       // Check responsecode
       if (responseCode==200)
       {
       		// Make sure no error is shown	
           // ShowError=false;       
           if (data instanceof Dictionary) {	            
				if (data["status"].equals("OK")) {
	            	if (data["title"].equals("GetPlanDevices")) {
						if (data["result"]!=null) {
							// devices/scenes/groups received: Create a devices list.
			            	status="ShowDevices";
			            	DevicesName=new [data["result"].size()];
			            	DevicesIdx=new [data["result"].size()];
			            	DevicesSwitchType=new [data["result"].size()];
			            	DevicesData=new [data["result"].size()];
			            	DevicesType=new [data["result"].size()];
			            	for (var i=0;i<data["result"].size();i++) {
			            		// Check if it is a device or a scene
	       						DevicesIdx[i]=data["result"][i]["devidx"];
	       						DevicesSwitchType[i]="Loading...";
	       						DevicesData[i]="Loading...";
			            		if (data["result"][i]["type"]==0) {
		       						DevicesName[i]=data["result"][i]["Name"];
		       						DevicesType[i]="Device";
		            			} else {
		       						DevicesName[i]=data["result"][i]["Name"].substring(8,data["result"][i]["Name"].length());
			       					DevicesType[i]="Scene";
		   						}
		        			}
		        			// Check if we remember were we were the last time;
		        			SetDeviceCursor();	
	        			} else { 
	        				status="Error";
	        				StatusText="Room has no devices";
        				}	    				
	    			} else if (data["title"].equals("Devices")) {
	    			
	    				// device info received, update the device
		            	status="ShowDeviceState";
		            	for (var i=0;i<DevicesIdx.size();i++) {
		            	    if (DevicesIdx[i].equals(data["result"][0]["idx"])) {
		   						DevicesData[i]=data["result"][0]["Data"];
		   						DevicesSwitchType[i]=data["result"][0]["SwitchType"];
	   						}
	            		}
					} else if (data["title"].equals("SwitchLight") or data["title"].equals("SwitchScene")) {
						// a scene, group of light was switched. Update the device status
		            	status="ShowDeviceState";
			           	DevicesData[devicecursor]="Command OK";
			            getDeviceStatus();	            	
	            	} else if (data["title"].equals("Plans")) {
						// Roomplans received, populate the roomlist.
		            	if (data["result"]!=null) {
		            		// we have rooms to populate!
			            	RoomsIdx=new [data["result"].size()];
			            	RoomsName=new [data["result"].size()];
			            	
			            	for (var i=0;i<data["result"].size();i++) {
			            		RoomsIdx[i]=data["result"][i]["idx"];
			            		RoomsName[i]=data["result"][i]["Name"];
			            	}
			            	// Set Room Cursor
			            	SetRoomCursor();
			            	status="ShowRooms";
		            				            	
	            		} else {
	            			// no roomplans in domoticz instance
	            			status="Error";
	            			StatusText="No roomplans configured";
            			}
        			} else if (data["title"].equals("Scenes")) {
        				// Scene(s) status(es) received, update the devicelist.
        				status="ShowDeviceState";
		            	if (data["result"]!=null) {
		            		// we cannot select on a specific scene, so cycle through the results
		            		for (var i=0;i<data["result"].size();i++) {
		            			if (data["result"][i]["idx"].equals(DevicesIdx[devicecursor])) {
		            				DevicesData[devicecursor]=data["result"][i]["Status"];
		            				DevicesType[devicecursor]=data["result"][i]["Type"];
		            			}
		            		}
		            	} else {
		            		// no scenes/groups returned
		            		status = "Error";
		            		StatusText="No scenes/groups";
		            	}
					} else {
						status="Error";
						StatusText="Unknown HTTP Response";
	        		}
            	} else {
            		status="Error";
	            	StatusText="Domoticz Error: "+data["status"];
            	}            		
	       } else {
	            // not parsable
	            status="Error";
	            StatusText="Not Parsable (Proxy?)";
	       }
	   } else if (responseCode==Comm.BLE_CONNECTION_UNAVAILABLE) {
	        // bluetooth not connected
	        status="Error";
	        StatusText="No Bluetooth";
	   } else if (responseCode==Comm.SECURE_CONNECTION_REQUIRED) {
	        // Some handsites require https
	        status="Error";
	        StatusText="phone requires HTTPS";
	   } else if (responseCode==Comm.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE) {
       		// Invalid API key
       		status="Error";
       		StatusText="Authentication Error"; 
	   } else if (responseCode==Comm.NETWORK_REQUEST_TIMED_OUT ) {
       		// No Internet
       		status="Error";
       		StatusText="No Internet";
   		} else if (responseCode==404) {
   			// Inavlid adress
   			status="Error";
   			StatusText="Invalid connection settings";		 
       } else {
       		// general Error
       		status="Error";
       		StatusText="Error "+responseCode;
	    }
    	Ui.requestUpdate();
	}
    
    // Update the view
    function onUpdate(dc) {
    
        if (status.equals("Fetching Devices")) {
	    	Line1="";
	    	Line2="Loading devices";
	    	Line3="";
        } else if (status.equals("Fetching Rooms") or status.equals("FetchingDeviceState")) {
	    	Line1="";
	    	Line2="Loading rooms";
	    	Line3="";
	    } else if (status.equals("Error")) {
	    	Line1="Error";
	    	Line2=StatusText;
	    	Line3="";
    	} else if (status.equals("ShowDevices") or status.equals("ShowDeviceState") or status.equals("Sending Command")) {
    	
    		if (devicecursor==0) 
    		{
    	    	Line1=DevicesName[DevicesIdx.size()-1];
	    	} else {
	    		Line1=DevicesName[devicecursor-1];
    		}
    		
    	    Line2=DevicesName[devicecursor];
    	    Line2Status=DevicesData[devicecursor];
    	    
    	    if (devicecursor==DevicesIdx.size()-1)
    	    {
    		    Line3=DevicesName[0];  
		    } else {	    
	    	    Line3=DevicesName[devicecursor+1];
    	    }
	    } else if (status.equals("ShowRooms")) {
    		if (roomcursor==0) 
    		{
    	    	Line1=RoomsName[RoomsIdx.size()-1];
	    	} else {
	    		Line1=RoomsName[roomcursor-1];
    		}
    		
    	    Line2=RoomsName[roomcursor];
    	    Line2Status="";
    	    
    	    if (roomcursor==RoomsIdx.size()-1)
    	    {
    		    Line3=RoomsName[0];  
		    } else {	    
	    	    Line3=RoomsName[roomcursor+1];
    	    }	    	
    	}	 else {
    	   Line1="Unknown status";
    	   Line2=status;
    	   Line3="";
		}       

		// draw the screen. 1st: clear the current screen and set color
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

		
		if (status.equals("Fetching Devices") or status.equals("Fetching Rooms") or status.equals("Error")) {
			// Status screen
			// load logo
			var image = Ui.loadResource( Rez.Drawables.DomoticzLogo);
			dc.drawBitmap(dc.getWidth()/2-30,25,image);
			
			// Draw text
	        dc.drawText(dc.getWidth()/2,dc.getHeight()*4/8,Graphics.FONT_MEDIUM,Line2,Graphics.TEXT_JUSTIFY_CENTER);
		 	
		} else {
        	// menu screen
        	
	        // create menu structure by dividing screen in 3 area's
	        dc.drawLine(0,dc.getHeight()/4,dc.getWidth(),dc.getHeight()/4);
	        dc.drawLine(0,dc.getHeight()*3/4,dc.getWidth(),dc.getHeight()*3/4);
        
			// determine offsets and draw the menu	        
	        var medium_offset=dc.getFontHeight(Graphics.FONT_MEDIUM)/2;
	        var large_offset=dc.getFontHeight(Graphics.FONT_LARGE)/2;
	        dc.drawText(dc.getWidth()/2,dc.getHeight()*1/8-medium_offset,Graphics.FONT_MEDIUM,Line1,Graphics.TEXT_JUSTIFY_CENTER);
	        
	        if (status.equals("ShowRooms")) {
	        	// only one line
		        dc.drawText(dc.getWidth()/2,dc.getHeight()/2-large_offset,Graphics.FONT_LARGE,Line2,Graphics.TEXT_JUSTIFY_CENTER);
	        } else {
	        	// two lines
	        	dc.drawText(dc.getWidth()/2,dc.getHeight()*2/8,Graphics.FONT_LARGE,Line2,Graphics.TEXT_JUSTIFY_CENTER);
		        dc.drawText(dc.getWidth()/2,dc.getHeight()*4/8,Graphics.FONT_LARGE,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
        	}
	        dc.drawText(dc.getWidth()/2,dc.getHeight()*7/8-medium_offset,Graphics.FONT_MEDIUM,Line3,Graphics.TEXT_JUSTIFY_CENTER);
        }
        	        
        if (status.equals("ShowDevices")) {
        	// make sure the shown device will be updated to latest status
        	delayTimer.start(method(:getDeviceStatus),500,false);
        }
        
    }
    
    function getDeviceStatus() {
    
    	if (DevicesType[devicecursor].equals("Device")) {
    		// current device is a device
    		makeWebRequest(GETDEVICESTATUS);
    	} else {
    		// current device is a scene
    		makeWebRequest(GETSCENESTATUS);
    	}
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
        // Save cursors
        var app=Application.getApp();
        app.setProperty("devicecursor",devicecursor);       
        app.setProperty("roomcursor", roomcursor);       
        app.setProperty("deviceidx",deviceidx);       
        app.setProperty("devicetype",devicetype);       
        app.setProperty("roomidx", roomidx);       
        app.setProperty("status", status);     
          
       
    }

}
