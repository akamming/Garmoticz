using Toybox.WatchUi;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.StringUtil as Su;
using Toybox.Application as App;
using Toybox.Timer as Timer;
using Toybox.System;


// define functions for debugging on console which is not executed in release version
(:debug) function Log(message) {
	System.println(message);
}

(:release) function Log(message) {
	// do nothing
}


// Global vars, so all classes can access them
var roomcursor=0;
var devicecursor=0;
var roomidx=0;
var deviceidx=0;
var devicetype;
var status="Fetching Rooms";
var RoomsIdx;
var RoomsName;
var DevicesName;
var DevicesIdx;
var DevicesData;
var DevicesType;
var Refreshing=false;




// Commands sent by delegate handler
enum { 
	NEXTITEM,
	PREVIOUSITEM,
	SELECT,
	BACK,
	MENU
}

// commands for getwebrequest
enum { 
	GETROOMS,  
	GETDEVICES,
	GETDEVICESTATUS,
	SENDONCOMMAND,
	SENDOFFCOMMAND,
	SENDSTOPCOMMAND,
	GETSCENESTATUS,
	SWITCHONGROUP,
	SWITCHOFFGROUP
}

const BACKMENUITEM = 10000;
const OPENMENUITEM=10001;
const CLOSEMENUITEM=10002;
const STOPMENUITEM=10003;

class GarmoticzView extends WatchUi.View {

	// DeviceTypes
	enum {
		ONOFF,
		INVERTEDBLINDS,
		VENBLIND,
		PUSHON,
		PUSHOFF,
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

		-300 => Rez.Strings.ERROR_NETWORK_TIMEOUT,
		-400 => Rez.Strings.ERROR_NETWORK_TIMEOUT,
		
		-104 => Rez.Strings.ERROR_BLE_CONNECTION_UNAVAILABLE,
		
		-3 => Rez.Strings.ERROR_BLE_TIMEOUT,
		-2 => Rez.Strings.ERROR_BLE_TIMEOUT
	};
	
	// Global vars
	var StatusText="";
	var ErrorCode=0;
	var Line1="";
	var Line2="";
	var Line2Status="";
	var Line3="";
	


	
	// Timer to prevent too many url's when scrolling through devices
	var delayTimer;
	const delayTime=500; // number of milliseconds before status is requested
		
    function initialize() {
		// parent call
        View.initialize();

        // initializez timer
        delayTimer=new Timer.Timer();
        
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
		        	status="Fetching Devices";
	        	} else {
	        		// we have retrieved a valid config
	        		status="ShowDevice";
	        		
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
		        ResetApplication();
	        	} else {
	        		// we have retrieved a valid config
	        		status="ShowRooms";
	    		}
	        } else {	        	
	        	// unknown state, go to initial state
	        	// status="Start Screen";
	        	ResetApplication();
	        }
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }
    
	    // Handle Command from Delegate view
    function HandleCommand (data)
    {
    	// stop the timers (if new action was done too fast, no update from device will take place)
    	delayTimer.stop();
    	
         if (data==NEXTITEM) {
         	NextItem();
     	} else if (data==PREVIOUSITEM) {
     		PreviousItem();
 		} else if (data==SELECT) {
 			Select();
 		} else if (data==MENU) {
 			ResetApplication();
 		} else if (data==BACK) {
 			if (status.equals("ShowDeviceState"))  {
 				if (RoomsIdx==null) {
		 			ResetApplication();
	 			} else {
		 			SetRoomCursor();
			     	status="ShowRooms";
			     	Ui.requestUpdate();
		     	}
 			} else {
 	 			popView(WatchUi.SLIDE_RIGHT);
 			
 			}
 		}
    }
    
    function ResetApplication()
    {
 		status="Fetching Rooms";
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
			
		} else if (status.equals("ShowRooms")) {
			roomcursor++;
			if (roomcursor==RoomsIdx.size())
			{ 
				roomcursor=0;
			}
			roomidx=RoomsIdx[roomcursor];
		} 
		Ui.requestUpdate();			
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
		} else if (status.equals("ShowRooms")) {
			roomcursor--;
			if (roomcursor<0) 
			{
				roomcursor=RoomsIdx.size()-1;
			}
			roomidx=RoomsIdx[roomcursor];
		} 
		Ui.requestUpdate();
	}
	
	function Select()
	{
		if (status.equals("ShowRooms")) {
			// go to devices menu of selected room
			// roomcursor=item;
    		roomidx=RoomsIdx[roomcursor];
    		devicecursor=0;
			// RoomsIdx=null;
			// RoomsName=null;
			status="Fetching Devices";
			Ui.requestUpdate();
			
		} else if (status.equals("ShowDeviceState") or status.equals("ShowDevice")) {
			// check if we have to flip a switch
			if (DevicesType[devicecursor]==ONOFF) {
				// Device is a switchable device

		    	// communicate status
		    	status="Sending Command";	
	        	Refreshing=true;

				// handle differently of on/closed and off/open
				if (DevicesData[devicecursor].equals(Ui.loadResource(Rez.Strings.ON)) or DevicesData[devicecursor].equals(Ui.loadResource(Rez.Strings.CLOSED))) {
					DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_OFF);
					makeWebRequest(SENDOFFCOMMAND);
				} else {
					DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_ON);
					makeWebRequest(SENDONCOMMAND);
				}
				
				// update the UI
				Ui.requestUpdate();
			} 
			
			if (DevicesType[devicecursor]==INVERTEDBLINDS) {
				// Device is a switchable device

		    	// communicate status
		    	status="Sending Command";	
	        	Refreshing=true;

				// handle differently of on/closed and off/open
				if (DevicesData[devicecursor].equals(Ui.loadResource(Rez.Strings.OPEN))) {
					DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_OFF);
					makeWebRequest(SENDOFFCOMMAND);
				} else {
					DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_ON);
					makeWebRequest(SENDONCOMMAND);
				}
				
				// update the UI
				Ui.requestUpdate();
			} 
			
			
			if (DevicesType[devicecursor]==VENBLIND) {
				// Device is a switchable Venetian Blinds, so 3 commands available to choose from: Present menu
	        	var menu = new WatchUi.Menu();
				menu.setTitle(Ui.loadResource(Rez.Strings.BLINDS));			            	
   				menu.addItem(Ui.loadResource(Rez.Strings.OPEN),OPENMENUITEM);
   				menu.addItem(Ui.loadResource(Rez.Strings.CLOSE),CLOSEMENUITEM);
   				menu.addItem(Ui.loadResource(Rez.Strings.STOP),STOPMENUITEM);
				menu.addItem(Ui.loadResource(Rez.Strings.BACK),BACKMENUITEM); 
				
				// push menu
				WatchUi.pushView(menu, new GarmoticzMenuInputDelegate(), WatchUi.SLIDE_IMMEDIATE);

			} 
			
			
			
			if (DevicesType[devicecursor]==PUSHON) {
				// Device is a switchable device

		    	// communicate status
		    	status="Sending Command";	
	        	Refreshing=true;

				makeWebRequest(SENDONCOMMAND);
				
				// update the UI
				Ui.requestUpdate();
			} 
			
			if (DevicesType[devicecursor]==PUSHOFF) {
				// Device is a switchable device

		    	// communicate status
		    	status="Sending Command";	
	        	Refreshing=true;

				makeWebRequest(SENDOFFCOMMAND);
				
				// update the UI
				Ui.requestUpdate();
			} 
			
			if (DevicesType[devicecursor]==GROUP) {
		    	// communicate status
		    	status="Sending Command";	
	        	Refreshing=true;

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
	        	Refreshing=true;
				
				// update the UI
				Ui.requestUpdate();
			}
		} else if (status.equals("ShowRooms")) {
			// room selected, fetch devices
			devicecursor=0;
			RoomsIdx=null;
			RoomsName=null;
			status="Fetching Devices";
			// Ui.requestUpdate();
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

		// initialize vars
		var url;
		var prefix;
		var Domoticz_Protocol;

		if (App.getApp().getProperty("PROP_PROTOCOL")==0) {
			Domoticz_Protocol="http";
		} else {
			Domoticz_Protocol="https";
		}
				
		if (App.getApp().getProperty("PROP_USERNAME").length()==0) {
	    	prefix=Domoticz_Protocol+"://"+App.getApp().getProperty("PROP_ADRESS")+":"+App.getApp().getProperty("PROP_PORT")+"/json.htm?";			
		} else {
	    	//needed vars
	    	prefix=Domoticz_Protocol+"://"+App.getApp().getProperty("PROP_ADRESS")+":"+App.getApp().getProperty("PROP_PORT")+"/json.htm?username="+Su.encodeBase64(App.getApp().getProperty("PROP_USERNAME"))+"&password="+Su.encodeBase64(App.getApp().getProperty("PROP_PASSWORD"))+"&";
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
    	}	else if (action==SENDSTOPCOMMAND) {
    		// build url to switch off device
    		url=prefix+"type=command&param=switchlight&idx="+DevicesIdx[devicecursor]+"&switchcmd=Stop"; // Send stop command
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
    
    // Receive the data from the web request
    function onReceive(responseCode, data) 
    {
    	Refreshing=false; // data received

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
		        			
        					status="ShowDevice";
        					SetDeviceCursor();
		        			
	        			} else { 
	        				status="Error";
	        				StatusText=Ui.loadResource(Rez.Strings.STATUS_ROOM_HAS_NO_DEVICES);
	        				ErrorCode=0;
        				}	    				
	    			} else if (data["title"].equals("Devices")) {
	    				// device info received, update the device
	    				Refreshing=false; // remove updates statusline
	    				
		            	for (var i=0;i<DevicesIdx.size();i++) {
		            	    if (DevicesIdx[i].equals(data["result"][0]["idx"])) {
		            	    	// device i is the device to update!
       							if (data["result"][0]["SwitchType"]!=null) { // it is a switch
	       							
	       							// set datafield
       								if (data["result"][0]["Data"].equals("On")) {
	       								// switch is on
	       								DevicesData[i]=Ui.loadResource(Rez.Strings.ON);
	       							} else if (data["result"][0]["Data"].equals("Off")) {
	       								// switch is off
	       								DevicesData[i]=Ui.loadResource(Rez.Strings.OFF);
       								} else if (data["result"][0]["Data"].equals("Open")) {
	       								// switch is on
	       								DevicesData[i]=Ui.loadResource(Rez.Strings.OPEN);
	       							} else if (data["result"][0]["Data"].equals("Closed")) {
	       								// switch is off
	       								DevicesData[i]=Ui.loadResource(Rez.Strings.CLOSED);
       								} else if (data["result"][0]["Data"].equals("Stopped")) {
	       								// switch is off
	       								DevicesData[i]=Ui.loadResource(Rez.Strings.STOPPED);
       								} else {
       									DevicesData[i]=data["result"][0]["Data"];
       								}					
       								
       								// Set switchtype and correct data if needed
	       							if (data["result"][0]["SwitchType"].equals("On/Off") or data["result"][0]["SwitchType"].equals("Blinds")) { // switch can be controlled by user
	       								DevicesType[i]=ONOFF;
       								} else if (data["result"][0]["SwitchType"].equals("Blinds Inverted")) {
       									DevicesType[i]=INVERTEDBLINDS;
	       							} else if (data["result"][0]["SwitchType"].equals("Venetian Blinds US") or data["result"][0]["SwitchType"].equals("Venetian Blinds EU")) { // blinds
	       								DevicesType[i]=VENBLIND;
	       							} else if (data["result"][0]["SwitchType"].equals("Push On Button")) { // PushOnButton
	       								DevicesType[i]=PUSHON;
	       								DevicesData[i]=Ui.loadResource(Rez.Strings.PUSHON);
	       							} else if (data["result"][0]["SwitchType"].equals("Push Off Button")) { // PushOffButton
	       								DevicesType[i]=PUSHOFF;
	       								DevicesData[i]=Ui.loadResource(Rez.Strings.PUSHOFF); 
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
	            			ErrorCode=0;
            			}
        			} else if (data["title"].equals("Scenes")) {
        				// Scene(s) status(es) received, update the devicelist.
        				Refreshing=false;
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
						ErrorCode=0;
	        		}
            	} else {
            		status="Error";
	            	StatusText=Ui.loadResource(Rez.Strings.STATUS_DOMOTICZ_ERROR)+data["status"];
	            	ErrorCode=0;
            	}            		
	       } else {
	            // not parsable
	            status="Error";
	            StatusText=Ui.loadResource(Rez.Strings.STATUS_NOT_PARSABLE);
	            ErrorCode=0;
	       }
	   } else {
	   		status="Error";
	   	    if (ConnectionErrorMessages[responseCode]==null) {
		   	    // assume general Error, since it was not logged. Also show  the number for debugging purposes..
		   		status="Error";
		   		StatusText=Ui.loadResource(Rez.Strings.ERROR_GENERAL_CONNECTION_ERROR);
		   		ErrorCode=responseCode;
			} else {
				// specific error
	       		status="Error";
	       		StatusText=Ui.loadResource(ConnectionErrorMessages[responseCode]); 
	       		ErrorCode=responseCode;
       		}
   		}
   		Ui.requestUpdate();
	}
    
    // Update the view
    function onUpdate(dc) {
    	
    	// A Menu command might have been given)
    	if (status.equals("SendStopCommand")) {
    		DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_STOPPING);
			makeWebRequest(SENDSTOPCOMMAND);
			status="Sending Command";
    	} else if (status.equals("SendCloseCommand")) {
    		DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_ON);
			makeWebRequest(SENDONCOMMAND);
			status="Sending Command";
    	} else if (status.equals("SendOpenCommand")) {
    		DevicesData[devicecursor]=Ui.loadResource(Rez.Strings.STATUS_SWITCHING_OFF);
			makeWebRequest(SENDOFFCOMMAND);
			status="Sending Command";
		}
    
    	// set the correct lines
        if (status.equals("Fetching Devices") or status.equals("DeviceFetchInProgress")) {
	    	Line1="";
	    	Line2=Ui.loadResource(Rez.Strings.STATUS_LOADING_DEVICES);
	    	Line3="";
	        if (status.equals("Fetching Devices")) {
		    	// make sure we get the devices!
	        	makeWebRequest(GETDEVICES);
	        	status="DeviceFetchInProgress";
	        	Refreshing=true;
	        } 
	    } else if (status.equals("Fetching Rooms") or status.equals("RoomFetchInProgress")) {
	    	Line1="";
	    	Line2=Ui.loadResource(Rez.Strings.STATUS_LOADING_ROOMS);
	    	Line3="";
	        if (status.equals("Fetching Rooms")) {
		    	// Make sure we get the rooms!
		    	makeWebRequest(GETROOMS);
		    	status="RoomFetchInProgress";
	        	Refreshing=true;
		    } 
    	} else if (status.equals("Error")) {
	    	Line1="Error";
	    	Line2=StatusText;
	    	if (ErrorCode==0) {
	    		Line2Status="";
    		} else {
    			Line2Status=ErrorCode.toString();
			}
	    	Line3="";
    	} else if (status.equals("Start Screen") or status.equals("ShowDevices")) {
    		Line1="";
    		Line2="Garmoticz";
    		// Line2Status=Ui.loadResource(Rez.Strings.STATUS_PRESS_MENU);
    		Line2Status="oeps...";
    		Line3="";
		} else if (status.equals("ShowRooms")) {
			if (roomcursor==0) {
				Line1=RoomsName[RoomsIdx.size()-1];
			} else {
				Line1=RoomsName[roomcursor-1];
			}
			
			Line2=RoomsName[roomcursor];
			Line2Status="";
			
			if (roomcursor==RoomsIdx.size()-1) {
				Line3=RoomsName[0];
			} else {
				Line3=RoomsName[roomcursor+1];
			}
    	} else if (status.equals("ShowDeviceState") or status.equals("ShowDevice") or status.equals("Sending Command")) {
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
    	    if (status.equals("ShowDevice")) {
    	    	getDeviceStatus();
    	    	status="ShowDeviceState";
    	    }	    	
    	} else {
    	   Line1=Ui.loadResource(Rez.Strings.STATUS_UNKNOWN_STATUS);
    	   Line2=status;
    	   Line3="";
		}       

		// draw the screen. 1st: clear the current screen and set color
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

		// set offset
		var offset=10;

		
		// load logo if only line 2 needs to be shown, otherwise: Draw lines
		if (status.equals("ShowDevice") or status.equals("ShowDeviceState") or status.equals("Sending Command") or status.equals("ShowRooms")) {
			dc.drawLine(0,dc.getHeight()/4-0*offset,dc.getWidth(),dc.getHeight()/4-0*offset);
			dc.drawLine(0,dc.getHeight()/4*3+0*offset,dc.getWidth(),dc.getHeight()/4*3+0*offset);			
		} else {
			var image = Ui.loadResource( Rez.Drawables.Domoticz_Logo);
			dc.drawBitmap(dc.getWidth()/2-30,2,image);
		}	
		
		
		if (status.equals("ShowDeviceState") or status.equals("ShowDevices") or status.equals ("Sending Command") or status.equals("ShowDevice") or status.equals("Start Screen") or status.equals("Error") ) {
        	// two lines
        	if (dc.getTextWidthInPixels(Line2,Graphics.FONT_LARGE)>dc.getWidth()) { // smaller font is bigger than screen
	        	if (dc.getTextWidthInPixels(Line2,Graphics.FONT_MEDIUM)>dc.getWidth()) { // on fenix 5 sometimes even smaller font is too big
		        	dc.drawText(dc.getWidth()/2,dc.getHeight()*5/16+0*offset,Graphics.FONT_XTINY,Line2,Graphics.TEXT_JUSTIFY_CENTER);
	        	} else {
		        	dc.drawText(dc.getWidth()/2,dc.getHeight()*5/16+0*offset,Graphics.FONT_MEDIUM,Line2,Graphics.TEXT_JUSTIFY_CENTER);
	        	}
        	} else {
	        	dc.drawText(dc.getWidth()/2,dc.getHeight()*5/16+0*offset,Graphics.FONT_LARGE,Line2,Graphics.TEXT_JUSTIFY_CENTER);
        	}
        	
        	if (dc.getTextWidthInPixels(Line2Status, Graphics.FONT_LARGE)>dc.getWidth()) { // small font if bigger than screen
	        	if (dc.getTextWidthInPixels(Line2Status, Graphics.FONT_MEDIUM)>dc.getWidth()) { // for some watches even medium is too big
			        dc.drawText(dc.getWidth()/2,dc.getHeight()*8/16+0*offset,Graphics.FONT_XTINY,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
		        } else {
			        dc.drawText(dc.getWidth()/2,dc.getHeight()*8/16+0*offset,Graphics.FONT_MEDIUM,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
		        }
	        } else {
		        dc.drawText(dc.getWidth()/2,dc.getHeight()*8/16+0*offset,Graphics.FONT_LARGE,Line2Status,Graphics.TEXT_JUSTIFY_CENTER);
	        }
	        
	        
		} else {
			// One Line
			if (dc.getTextWidthInPixels(Line2, Graphics.FONT_LARGE)>dc.getWidth()) {
    			if (dc.getTextWidthInPixels(Line2, Graphics.FONT_MEDIUM)>dc.getWidth()) {
		    		dc.drawText(dc.getWidth()/2,dc.getHeight()*4/8-2*offset,Graphics.FONT_XTINY,Line2,Graphics.TEXT_JUSTIFY_CENTER);
	    		} else {
		    		dc.drawText(dc.getWidth()/2,dc.getHeight()*4/8-2*offset,Graphics.FONT_MEDIUM,Line2,Graphics.TEXT_JUSTIFY_CENTER);
	    		}
        	} else {
		        dc.drawText(dc.getWidth()/2,dc.getHeight()*4/8-2*offset,Graphics.FONT_LARGE,Line2,Graphics.TEXT_JUSTIFY_CENTER);
	        }
        }
        
        // Draw additional items if in device of rooms mode
        if (status.equals("ShowDevice") or status.equals("ShowDeviceState") or status.equals("Sending Command") or status.equals("ShowRooms")) {
        	dc.drawText(dc.getWidth()/2,dc.getHeight()*1/16+offset,Graphics.FONT_XTINY,Line1,Graphics.TEXT_JUSTIFY_CENTER);
        	dc.drawText(dc.getWidth()/2,dc.getHeight()*13/16,Graphics.FONT_XTINY,Line3,Graphics.TEXT_JUSTIFY_CENTER);
        }
    

        if (Refreshing) {
	        // dc.drawText(dc.getWidth()/2,dc.getHeight()*13/16,Graphics.FONT_SMALL,Ui.loadResource(Rez.Strings.UPDATING),Graphics.TEXT_JUSTIFY_CENTER);
	        var bitmap=Ui.loadResource(Rez.Drawables.NetworkTrafficIcon);
	        dc.drawBitmap(dc.getWidth()/2-20, dc.getHeight()-30, bitmap);
        }

    }
    
    function getDeviceStatus() {
    	Refreshing=true;
    	if (DevicesType[devicecursor]==SCENE or DevicesType[devicecursor]==GROUP) {
    		// current device is a device
    		makeWebRequest(GETSCENESTATUS);
    	} else {
    		// current device is a scene
    		makeWebRequest(GETDEVICESTATUS);
    	}
    	Ui.requestUpdate();
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
        var app=Application.getApp();

		// if there are devices: Save them for faster startup        
        if (DevicesIdx!=null) {
	        // Save cursors
	        app.setProperty("devicecursor",devicecursor);       
	        app.setProperty("roomcursor", roomcursor);       
	        app.setProperty("deviceidx",deviceidx);       
	        app.setProperty("devicetype",devicetype);       
	        app.setProperty("roomidx", roomidx);       
	        app.setProperty("status", "ShowDeviceState");

        	// save devices, so they do not need to be retrieved at startup
        	app.setProperty("SizeOfDevices", DevicesIdx.size());
        	for (var i=0;i<DevicesIdx.size();i++) {
        		app.setProperty("DevicesIdx"+i,DevicesIdx[i]);
        		app.setProperty("DevicesName"+i,DevicesName[i]);
	       		app.setProperty("DevicesType"+i,DevicesType[i]);
	       		app.setProperty("DevicesData"+i,DevicesData[i]);
        	}
        } else {
	        app.setProperty("status", "Fetching Rooms");        	
        }
    }
}
