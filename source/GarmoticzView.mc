using Toybox.WatchUi;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.StringUtil as Su;
using Toybox.Application as App;
using Toybox.Timer as Timer;

// Commands sent by delegate handler
enum { 
	NEXTITEM,
	PREVIOUSITEM,
	SELECT,
	BACK,
	MENU
}

// DeviceTypes
enum {
	ONOFF,
	GROUP,
	SCENE,
	DEVICE
}

// mapping of technical errors (source: https://developer.garmin.com/downloads/connect-iq/monkey-c/doc/Toybox/Communications.html) to friendly user text.
// Every not mapped number is matched to 

const ConnectionErrorMessages = {
	-1001 => Rez.Strings.ERROR_HANDSET_REQUIRES_HTTPS,
	
	-403 => Rez.Strings.ERROR_TOO_MUCH_DATA,
	-402 => Rez.Strings.ERROR_TOO_MUCH_DATA,
	
	-401 => Rez.Strings.ERROR_INVALID_CONNECTION_SETTING ,
	404 => Rez.Strings.ERROR_INVALID_CONNECTION_SETTING,

	-400 => Rez.Strings.ERROR_INVALID_RESPONSE,
	
	-104 => Rez.Strings.ERROR_BLE_CONNECTION_UNAVAILABLE,
	
	-3 => Rez.Strings.ERROR_BLE_TIMEOUT,
	-2 => Rez.Strings.ERROR_BLE_TIMEOUT
};


class GarmoticzView extends WatchUi.View {
	// Global vars
	var StatusText="";
	var Line1="";
	var Line2="";
	var Line3="";
	var Line2Status="";
	
	var DevicesName;
	var DevicesIdx;
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
	const delayTime=1000;
	
	// commands from viewhandler
	enum { 
		GETROOMS,  
		GETDEVICES,
		GETDEVICESTATUS,
		SENDONCOMMAND,
		SENDOFFCOMMAND,
		GETSCENESTATUS,
		SWITCHONGROUP,
		SWITCHOFFGROUP
	}
		
    function initialize() {
        // initializez timer
        delayTimer=new Timer.Timer();
        
        View.initialize();
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
		
        // Reset values to readable if they are null  to prevent exceptions
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
   			// no status saved  or saved in malicious state, setting the app to an initial state.
        	status="Fetching Rooms";
   			
	    	makeWebRequest(GETROOMS);
        	
        } else {
	       // try to set correct state based on previous state
	       if (status.equals("ShowDeviceState")) {

	       		// See if we have rooms stored on the watch
	       		var Error=false; // for error handling
	       		var SizeOfDevices=app.getProperty("SizeOfDevices");
	       		
	       		if (SizeOfDevices==0 or SizeOfDevices==null) {
	       			// No config
	       			Error=true;
	       		} else {
	       			// Devices were saved, initialize arrays
	       			DevicesIdx = new [SizeOfDevices];	
	       			DevicesName = new [SizeOfDevices];
					// DevicesSwitchType = new [SizeOfDevices];
					DevicesData = new [SizeOfDevices];
					DevicesType = new [SizeOfDevices];
					// DevicesSubType = new [SizeOfDevices];
					
					// populate array
	       			for (var i=0;i<SizeOfDevices;i++) {
	       				DevicesIdx[i]=app.getProperty("DevicesIdx"+i);
	       				DevicesName[i]=app.getProperty("DevicesName"+i);
	       				// DevicesSwitchType[i]="Loading...";
	       				DevicesData[i]=app.getProperty("DevicesData"+i);
	       				DevicesType[i]=app.getProperty("DevicesType"+i);
	       				// DevicesSubType[i]=app.getProperty("DevicesSubType"+i);
	       				
	       				// check for errors
	       				if (DevicesIdx[i]==null or DevicesName[i]==null or DevicesType[i]==null or DevicesData[i]==null) {
	       					Error=true;
	       				} 
	       			}	
	       		}
	       		
	       		if (Error) {
	       			// there was an error, get the rooms from the domoticz instance
			    	makeWebRequest(GETDEVICES);
		        	status="Fetching Devices";
	        	} else {
	        		// we have retrieved a valid config
	        		status="ShowDevices";
	        		
    		        // make sure the shown device will be updated to latest status (using delay to prevent too many updates in case of fast scrolling)
        			delayTimer.start(method(:getDeviceStatus),delayTime,false);
	    		}

	       } else if (status.equals("ShowRooms")) {
	       		// See if we have rooms stored on the watch
	       		var Error=false; // for error handling
	       		var SizeOfRooms=app.getProperty("SizeOfRooms");
	       		
	       		if (SizeOfRooms==0 or SizeOfRooms==null) {
	       			// No config
	       			Error=true;
	       		} else {
	       			// Rooms were saved, initialize array
	       			RoomsIdx = new [SizeOfRooms];	
	       			RoomsName = new [SizeOfRooms];
	       			
	       			//populate array
	       			for (var i=0;i<SizeOfRooms;i++) {
	       				RoomsIdx[i]=app.getProperty("RoomsIdx"+i);
	       				RoomsName[i]=app.getProperty("RoomsName"+i);
	       				
	       				// check for errors
	       				if (RoomsIdx[i]==null or RoomsName[i]==null) {
	       					Error=true;
	       				} 
	       			}	
	       		}
	       		
	       		if (Error) {
	       			// there was an error, get the rooms from the domoticz instance
		        	status="Fetching Rooms";
			    	makeWebRequest(GETROOMS);
	        	} else {
	        		// we have retrieved a valid config
	        		status="ShowRooms";
	    		}
	        } else {
	        	
	        	// unknown state, go to initial state
	        	status="Fetching Rooms";
		    	makeWebRequest(GETROOMS);
	        }
        }
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
			delayTimer.start(method(:getDeviceStatus),delayTime,false);	            	
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
			delayTimer.start(method(:getDeviceStatus),delayTime,false);	            	
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
		if (status.equals("ShowDeviceState") or status.equals("ShowDevices")) {
			// check if we have to flip a switch
			if (DevicesType[devicecursor]==ONOFF) {
				// Device is a switchable device

		    	// communicate status
		    	status="Sending Command";	

				// handle differently of on and off
				if (DevicesData[devicecursor].equals(Ui.loadResource(Rez.Strings.ON))) {
					DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_OFF);
					makeWebRequest(SENDOFFCOMMAND);
				} else {
					DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_ON);
					makeWebRequest(SENDONCOMMAND);
				}
				
				// update the UI
				Ui.requestUpdate();
			} 
			if (DevicesType[devicecursor]==GROUP) {
		    	// communicate status
		    	status="Sending Command";	

				// handle differently of on and off
				if (DevicesData[devicecursor].equals(Ui.loadResource(Rez.Strings.ON))) {
					DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_OFF);
					makeWebRequest(SWITCHOFFGROUP);
				} else {
					DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_ON);
					makeWebRequest(SWITCHONGROUP);
				}
				
				// update the UI
				Ui.requestUpdate();

			} 
			if (DevicesType[devicecursor]==SCENE) {
		    	// communicate status
		    	status="Sending Command";	

				DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_ACTIVATING_SCENE);
				makeWebRequest(SWITCHONGROUP);
				
				// update the UI
				Ui.requestUpdate();
			}
		} else if (status.equals("ShowRooms")) {
			// room selected, fetch devices
			devicecursor=0;
			RoomsIdx=null;
			RoomsName=null;
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

		var Domoticz_UserName = App.getApp().getProperty("PROP_USERNAME");
		var Domoticz_Password= App.getApp().getProperty("PROP_PASSWORD");
		var Domoticz_Protocol=App.getApp().getProperty("PROP_PROTOCOL");
		if (App.getApp().getProperty("PROP_PROTOCOL")==0) {
			Domoticz_Protocol="http";
		} else {
			Domoticz_Protocol="https";
		}
		var Domoticz_Adress= App.getApp().getProperty("PROP_ADRESS");
		var Domoticz_Port= App.getApp().getProperty("PROP_PORT");
		
		var url;
		var prefix;
		
		
		if (Domoticz_Adress==null) {
			Domoticz_Adress="";
		}
		if (Domoticz_UserName.length()==0) {
	    	prefix=Domoticz_Protocol+"://"+Domoticz_Adress+":"+Domoticz_Port+"/json.htm?";			
		} else {
	    	//needed vars
	    	prefix=Domoticz_Protocol+"://"+Domoticz_Adress+":"+Domoticz_Port+"/json.htm?username="+Su.encodeBase64(Domoticz_UserName)+"&password="+Su.encodeBase64(Domoticz_Password)+"&";
		}	        
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
    	
    	System.println(url);
    	

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
    
    // Receive the data from the web request
    function onReceive(responseCode, data) 
    {
    	System.println("Responsecode :"+responseCode);
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
			            	// DevicesSwitchType=new [data["result"].size()];
			            	DevicesData=new [data["result"].size()];
			            	DevicesType=new [data["result"].size()];
			            	// DevicesSubType=new [data["result"].size()];
			            				            	
			            	for (var i=0;i<data["result"].size();i++) {
			            		
			            		// Check if it is a device or a scene
	       						DevicesIdx[i]=data["result"][i]["devidx"];
	       						// DevicesSwitchType[i]=Ui.loadResource(Rez.Strings.STATUS_DEVICE_STATUS_LOADING);
	       						DevicesData[i]=Ui.loadResource(Rez.Strings.STATUS_DEVICE_STATUS_LOADING);
	       						// DevicesSubType[i]=Ui.loadResource(Rez.Strings.STATUS_DEVICE_STATUS_LOADING);
			            		if (data["result"][i]["type"]==0) {
		       						DevicesName[i]=data["result"][i]["Name"];
		       						DevicesType[i]=DEVICE;
		            			} else {
		       						DevicesName[i]=data["result"][i]["Name"].substring(8,data["result"][i]["Name"].length());
			       					DevicesType[i]=SCENE; // can be scene or group, but this will be corrected when the def devices is loaded
		   						}
		        			}
		        			// Check if we remember were we were the last time;
		        			SetDeviceCursor();	
	        			} else { 
	        				status="Error";
	        				StatusText=Ui.loadResource(Rez.Strings.STATUS_ROOM_HAS_NO_DEVICES);
        				}	    				
	    			} else if (data["title"].equals("Devices")) {
	    			
	    				// device info received, update the device
	    				if (status.equals("ShowDevices")) {
			            	status="ShowDeviceState";
	    				}
	    				
	    				
		            	for (var i=0;i<DevicesIdx.size();i++) {
		            	    if (DevicesIdx[i].equals(data["result"][0]["idx"])) {
		            	    	// device i is the device to update!
	       						if ( data["result"][0]["SubType"].equals("Switch") or data["result"][0]["SubType"].equals("X10") ) {  // Device is a switch
	       							if (data["result"][0]["SwitchType"].equals("On/Off")) { // switch can be controlled by user
	       								DevicesType[i]=ONOFF;
       								} else if (data["result"][0]["SwitchType"].equals("Door Contact")) { // DWS detected
		       							if (data["result"][0]["Data"].equals("Open")) {
		       								// switch is on
		       								DevicesData[i]=Ui.loadResource(Rez.Strings.OPEN);
		       							} else if (data["result"][0]["Data"].equals("Closed")) {
		       								// switch is off
		       								DevicesData[i]=Ui.loadResource(Rez.Strings.CLOSED);
	       								}
	       							} else {
	       								DevicesData[i]=data["result"][0]["Data"]; // this should not happen. 
	       							}
       							} else if (data["result"][0]["SubType"].equals("kWh")) {  // kwh device: take the daily counter + usage as data
	       							DevicesData[i]=data["result"][0]["CounterToday"]+", "+data["result"][0]["Usage"];
	       						} else if (data["result"][0]["SubType"].equals("Gas")) {  // gas device: take the daily counter as data
	       							DevicesData[i]=data["result"][0]["CounterToday"];
       							} else if (data["result"][0]["SubType"].equals("Energy")) { // Smart meter: take the daily counters for usage and delivery and add current usage
       									DevicesData[i]=data["result"][0]["CounterToday"].substring(0,data["result"][0]["CounterToday"].length()-4)+", "+data["result"][0]["CounterDelivToday"]+", "+data["result"][0]["Usage"];
       							} else if (data["result"][0]["SubType"].equals("Text")) { // a text device: make sure max length=25
										if (data["result"][0]["Data"].length()>25) {
				   							DevicesData[i]=data["result"][0]["Data"].substring(0,24); 
										} else {
				   							DevicesData[i]=data["result"][0]["Data"];
										}
	       						} else { // The rest
	       						
		   							DevicesData[i]=data["result"][0]["Data"];
		   						}
	   						}
	            		}
	            		
					} else if (data["title"].equals("SwitchLight") or data["title"].equals("SwitchScene")) {
						// a scene, group of light was switched. Update the device status
		            	status="ShowDeviceState";
			           	DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_COMMAND_EXECUTED_OK);
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
	            			StatusText=Ui.loadResource(Rez.Strings.STATUS_NO_ROOMPLAN_CONFIGURED);
            			}
        			} else if (data["title"].equals("Scenes")) {
        				// Scene(s) status(es) received, update the devicelist.
        				if (status.equals("ShowDevices")) {
        					status="ShowDeviceState";
    					}
		            	if (data["result"]!=null) {
		            		// we cannot select on a specific scene, so cycle through the results
		            		for (var i=0;i<data["result"].size();i++) {
		            			if (data["result"][i]["idx"].equals(DevicesIdx[devicecursor])) {
		            			    if (data["result"][i]["Type"].equals("Scene")) {
		            			    	DevicesType[devicecursor]=SCENE;
		            			    } else {
		            			    	DevicesType[devicecursor]=GROUP;
		            			    }
	       							if (data["result"][i]["Status"].equals("On")) {
	       								DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.ON);
	       							} else if (data["result"][i]["Status"].equals("Off")) {
	       								DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.OFF);
       								} else if (data["result"][i]["Status"].equals("Mixed")) {
	       								DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.MIXED);       								
	       							} else {
			            				DevicesData[devicecursor]=data["result"][i]["Status"];
	       							}
		            			}
		            		}
		            	} else {
		            		// no scenes/groups returned
		            		status = "Error";
		            		StatusText=Ui.loadResource(Rez.Strings.STATUS_NO_SCENESORGROUPS);
		            	}
					} else {
						status="Error";
						StatusText=Ui.loadResource(Rez.Strings.STATUS_UNKNOWN_HTTP_RESPONSE);
	        		}
            	} else {
            		status="Error";
	            	StatusText=Ui.loadResource(Rez.Strings.STATUS_DOMOTICZ_ERROR)+data["status"];
            	}            		
	       } else {
	            // not parsable
	            status="Error";
	            StatusText=Ui.loadResource(Rez.Strings.STATUS_NOT_PARSABLE);
	       }
	   } else {
	   		status="Error";
	   	    if (ConnectionErrorMessages[responseCode]==null) {
		   	    // assume general Error, since it was not logged. Also show  the number for debugging purposes..
		   		status="Error";
		   		StatusText=Ui.loadResource(Rez.Strings.ERROR_GENERAL_CONNECTION_ERROR)+" ("+responseCode+")";
			} else {
				// specific error
	       		status="Error";
	       		StatusText=Ui.loadResource(ConnectionErrorMessages[responseCode]); 
       		}
   		}
   		Ui.requestUpdate();
	}
    
    // Update the view
    function onUpdate(dc) {
        if (status.equals("Fetching Devices")) {
	    	Line1="";
	    	Line2=Ui.loadResource(Rez.Strings.STATUS_LOADING_DEVICES);
	    	Line3="";
        } else if (status.equals("Fetching Rooms")) {
	    	Line1="";
	    	Line2=Ui.loadResource(Rez.Strings.STATUS_LOADING_ROOMS);
	    	Line3="";
	    } else if (status.equals("Error")) {
	    	Line1="Error";
	    	Line2=StatusText;
	    	Line3="";
    	} else if (status.equals("ShowDeviceState") or status.equals("ShowDevices") or status.equals("Sending Command")) {
    	
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
    	   Line1=Ui.loadResource(Rez.Strings.STATUS_UNKNOWN_STATUS);
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
	        	if (dc.getTextWidthInPixels(Line2,Graphics.FONT_LARGE)>dc.getWidth()) { // smaller font is bigger than screen
		        	dc.drawText(dc.getWidth()/2,dc.getHeight()*2/8,Graphics.FONT_MEDIUM,Line2,Graphics.TEXT_JUSTIFY_CENTER);
	        	} else {
		        	dc.drawText(dc.getWidth()/2,dc.getHeight()*2/8,Graphics.FONT_LARGE,Line2,Graphics.TEXT_JUSTIFY_CENTER);
	        	}
	        	if (dc.getTextWidthInPixels(Line2Status, Graphics.FONT_LARGE)>dc.getWidth()) { // small font if bigger than screen
			        dc.drawText(dc.getWidth()/2,dc.getHeight()*4/8,Graphics.FONT_MEDIUM,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
		        } else {
			        dc.drawText(dc.getWidth()/2,dc.getHeight()*4/8,Graphics.FONT_LARGE,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
		        }
        	}
	        dc.drawText(dc.getWidth()/2,dc.getHeight()*7/8-medium_offset,Graphics.FONT_MEDIUM,Line3,Graphics.TEXT_JUSTIFY_CENTER);
        }
        	        
        if (status.equals("ShowDevices")) {
        	// make sure the shown device will be updated to latest status
        	delayTimer.start(method(:getDeviceStatus),delayTime,false);
        }
        
    }
    
    function getDeviceStatus() {
    	if (DevicesType[devicecursor]==DEVICE or DevicesType[devicecursor]==ONOFF) {
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
        
        if (status.equals("ShowRooms")) {
        	// save rooms, so they do not need to be retrieved at startup
        	app.setProperty("SizeOfRooms", RoomsIdx.size());
        	for (var i=0;i<RoomsIdx.size();i++) {
        		app.setProperty("RoomsIdx"+i,RoomsIdx[i]);
        		app.setProperty("RoomsName"+i,RoomsName[i]);
        	}
        } else if (status.equals("ShowDeviceState")) {
        	// save rooms, so they do not need to be retrieved at startup
        	app.setProperty("SizeOfDevices", DevicesIdx.size());
        	for (var i=0;i<DevicesIdx.size();i++) {
        		app.setProperty("DevicesIdx"+i,DevicesIdx[i]);
        		app.setProperty("DevicesName"+i,DevicesName[i]);
	       		app.setProperty("DevicesType"+i,DevicesType[i]);
	       		// app.setProperty("DevicesSubType"+i,DevicesSubType[i]);
	       		app.setProperty("DevicesData"+i,DevicesData[i]);
        	}
        }
    }
}
