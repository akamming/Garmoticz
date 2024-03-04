using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.StringUtil as Su;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.WatchUi;



// DeviceTypes
enum {
	ONOFF,
	INVERTEDBLINDS,
	VENBLIND,
	PUSHON,
	PUSHOFF,
	GROUP,
	SCENE,
	DEVICE,
	SETPOINT,
	DIMMER,
	SELECTOR
}


// commands for getwebrequest
enum {
	GETROOMS,
	GETDEVICES,
	GETDEVICESTATUS,
	SENDONCOMMAND,
	SENDOFFCOMMAND,
	SENDSTOPCOMMAND,
	SENDSETPOINT,
	SENDSELECTOR,
	SENDDIMMERVALUE,
	GETSCENESTATUS,
	SWITCHONGROUP,
	SWITCHOFFGROUP
}



// define functions for debugging on console which is not executed in release version

class Domoticz {
    public var roomItems as Lang.Dictionary<Lang.Number,WatchUi.MenuItem> = {};  // will contain the objects with the menu items of the rooms
    public var deviceItems as Lang.Dictionary<Lang.Number,DomoticzMenuItem or DomoticzToggleMenuItem> = {};  // will contain the objects with the menu items of the devices
	public var deviceIDX  as Lang.Array<Lang.Number> = []; // will store the idx numbers of the menu items for quick reference
	private var _roomscallback;
	private var _devicescallback;
	private var currentDevice; // holds the current index of the menuitems
	private var currentIDX as Lang.Number=0; // holds the current index of the domoticz device (or scene/group)
	private var currentRoom;
	private var delayTimer;
	private var setpoint;
	private var dimmerlevel;
	private const delayTime=1000; // number of milliseconds before status is requested
	private const toggleDeviceTypes=[ONOFF,GROUP,DIMMER]; // These devicetypes will get a toggle in the menu


	const ConnectionErrorMessages = {
		-1001 => Rez.Strings.ERROR_HANDSET_REQUIRES_HTTPS,

		-403 => Rez.Strings.ERROR_TOO_MUCH_DATA,
		-402 => Rez.Strings.ERROR_TOO_MUCH_DATA,

		-401 => Rez.Strings.ERROR_INVALID_CONNECTION_SETTING ,
		404 => Rez.Strings.ERROR_INVALID_CONNECTION_SETTING,

		-400 => Rez.Strings.ERROR_INVALID_RESPONSE,

		-300 => Rez.Strings.ERROR_NETWORK_TIMEOUT,

		-104 => Rez.Strings.ERROR_BLE_CONNECTION_UNAVAILABLE,

		-3 => Rez.Strings.ERROR_BLE_TIMEOUT,
		-2 => Rez.Strings.ERROR_BLE_TIMEOUT
	};

    public function initialize()
    {
		// initializez timer
        delayTimer=new Timer.Timer();
    }

    public function populateRooms(callbackhandler)
    {
        _roomscallback=callbackhandler;
        makeWebRequest(GETROOMS,null,method(:onReceiveRooms));
    }

	public function populateDevices(callbackhandler, _currentRoom) {
		currentRoom=_currentRoom;
		_devicescallback=callbackhandler;
		makeWebRequest(GETDEVICES,currentRoom,method(:onReceiveDevices));
	}

	public function setLevelDevice(index as Lang.Number, Level as Lang.Number) {
		dimmerlevel=Level;
		currentDevice=index;
		currentIDX=deviceIDX[index];
		deviceItems[index].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_SENDING_COMMAND));
		WatchUi.requestUpdate();
		makeWebRequest(SENDDIMMERVALUE,currentIDX,method(:onReceive));
	}

	public function sendSetpoint(index as Lang.Number, Setpoint as Lang.Float) {
		setpoint=Setpoint;
		currentDevice=index;
		currentIDX=deviceIDX[index];
		deviceItems[index].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_SENDING_COMMAND));
		WatchUi.requestUpdate();
		makeWebRequest(SENDSETPOINT,currentIDX,method(:onReceive));
	}
	public function switchOnOffDevice(index as Lang.Number, state) {
		// function to switch device. state = true means "on", false means "off"

		// remember device
		currentDevice=index;
		currentIDX=deviceIDX[index];
		if (state) {
			// we have to switch on
			deviceItems[index].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_SWITCHING_ON));
			WatchUi.requestUpdate();
			makeWebRequest(SENDONCOMMAND,currentIDX,method(:onReceive));
		} else {
			deviceItems[index].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_SWITCHING_OFF));
			WatchUi.requestUpdate();
		    makeWebRequest(SENDOFFCOMMAND,currentIDX,method(:onReceive)); 
		}
	}

	public function switchOnOffGroup(index, state) {
		// function to switch group or scene. state = true means "on", false means "off"

		// remember device
		currentDevice=index;
		currentIDX=deviceIDX[index];
		if (state) {
			// we have to switch on
			deviceItems[index].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_SWITCHING_ON));
			WatchUi.requestUpdate();
			makeWebRequest(SWITCHONGROUP,currentIDX,method(:onReceive));
		} else {
			deviceItems[index].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_SWITCHING_OFF));
			WatchUi.requestUpdate();
		    makeWebRequest(SWITCHOFFGROUP,currentIDX,method(:onReceive)); 
		}
	}

	public function getDeviceStatus(device) {

        var idx = deviceIDX[device];
    	if (deviceItems[device].getDeviceType()==SCENE or deviceItems[device].getDeviceType()==GROUP) {
    		// current device is a device
    		makeWebRequest(GETSCENESTATUS,idx,method(:onReceive));
    	} else {
    		// current device is a scene
    		makeWebRequest(GETDEVICESTATUS,idx,method(:onReceive));
    	}
    }

	function getCurrentDeviceStatus() {
		getDeviceStatus(currentDevice);
	}


	function getUrl() {
		var url;
		var Domoticz_Protocol;

		if (App.Properties.getValue("PROP_PROTOCOL")==0) {
			Domoticz_Protocol="http";
		} else {
			Domoticz_Protocol="https";
		}

		url=Domoticz_Protocol+"://"+App.Properties.getValue("PROP_ADRESS")+":"+App.Properties.getValue("PROP_PORT");
		if(App.Properties.getValue("PROP_PATH")!="") {
			url += App.Properties.getValue("PROP_PATH");
		}
		url += "/json.htm";
		return url;
	}

	function getOptions() {
		var options;

		if (App.Properties.getValue("PROP_USERNAME").length()==0) {
			options={
				:headers => {
					"Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
				}
			};
		} else {
			options = {
				:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
				:headers => {
					"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
					"Authorization" => "Basic "+Su.encodeBase64(App.Properties.getValue("PROP_USERNAME")+":"+App.Properties.getValue("PROP_PASSWORD"))
				}
	        };
			
		}
		return options;
	}

	function callUrl(url,options,params,callback) {
		// Make the reqsetpoiuest
		Log("Calling "+url+"with params "+params);
        Comm.makeWebRequest(
            url,
			params,
			options,
            callback
	     );  

	}

    function makeWebRequest(action,idx,callback) {
		// initialize vars
		var params = {};
		var options = getOptions();
		var url=getUrl();

    	// populate parameters;
    	if (action==GETDEVICES) {
			params.put("type","command");
	    	params.put("param","getdevices");
	    	params.put("filter","all");
			params.put("used","true");
			params.put("favorite",0);
			params.put("order","[Order]");
			params.put("plan",idx);
    	}	else if (action==GETDEVICESTATUS) {
    		params.put("type","command");
    		params.put("param","getdevices");
    		params.put("rid",idx);
    	}	else if (action==GETSCENESTATUS) {
			params.put("type","command");
    		params.put("param","getscenes");
    	}	else if (action==GETROOMS) {
			params.put("type","command");
    		params.put("param","getplans");
    		params.put("order","Order");
    		params.put("used","true");
    	}	else if (action==SENDONCOMMAND) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",idx);
    		params.put("switchcmd","On");
    	}	else if (action==SENDOFFCOMMAND) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",idx);
    		params.put("switchcmd","Off");
    	}	else if (action==SENDSTOPCOMMAND) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",idx);
    		params.put("switchcmd","Stop");
    	}	else if (action==SENDSETPOINT) {
    		params.put("type","command");
    		params.put("param","setsetpoint");
    		params.put("idx",idx);
    		params.put("setpoint",setpoint);
    	}	else if (action==SENDSELECTOR) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",idx);
			if (dimmerlevel==0) {
				params.put("switchcmd","Off");
			} else {
				params.put("switchcmd","Set Level");
				params.put("level",dimmerlevel);
			}
    	}	else if (action==SENDDIMMERVALUE) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",idx);
    		params.put("switchcmd","Set Level");
    		params.put("level",dimmerlevel);
    	}	else if (action==SWITCHOFFGROUP) {
    		params.put("type","command");
    		params.put("param","switchscene");
    		params.put("idx",idx);
    		params.put("switchcmd","Off");
    	}	else if (action==SWITCHONGROUP) {
       		params.put("type","command");
    		params.put("param","switchscene");
    		params.put("idx",idx);
    		params.put("switchcmd","On");
    	} else {
    		url="unknown url";
        }
		// Make the request
		 callUrl(url,options,params,callback);
	}

	function getMenuIndexfromDomoticzIndexforDevice(domoticzIndex as Lang.Number) {
		var menuIndex=null;
		for (var i=0;i<deviceIDX.size();i++) {
			if (deviceItems[i].getDeviceType()!=SCENE and deviceItems[i].getDeviceType()!=GROUP and deviceIDX[i].toNumber()==domoticzIndex.toNumber()) {
				menuIndex=i;
			}
		}
		return menuIndex;
	}

	function getMenuIndexfromDomoticzIndexforGroupOrScene(domoticzIndex as Lang.Number) {
		var menuIndex=null;
		for (var i=0;i<deviceIDX.size();i++) {
			if ((deviceItems[i].getDeviceType()==SCENE or deviceItems[i].getDeviceType()==GROUP) and deviceIDX[i].toNumber()==domoticzIndex.toNumber()) {
				menuIndex=i;
			}
		}
		return menuIndex;
	}


	function updateDeviceStatus(data as Lang.Dictionary<Lang.String,Lang.String or Lang.Number>) {
		var devicetype=getDeviceType(data);
		var devicedata=getDeviceData(data,devicetype);
		var menuidx=getMenuIndexfromDomoticzIndexforDevice(data["idx"]);
		if (menuidx!=null) {
			if (devicetype==SELECTOR) {
				var Levels = getLevels(data["LevelNames"]);
				deviceItems[menuidx].setLevels(Levels);
				devicedata=Levels[data["LevelInt"]];
			}
			deviceItems[menuidx].setLabel(data["Name"]);
			deviceItems[menuidx].setSubLabel(devicedata);
			
			if (toggleDeviceTypes.indexOf(devicetype)>=0) { 
				var enabled=true;
				if (devicedata.equals(WatchUi.loadResource(Rez.Strings.OFF))) {
					enabled=false;
				}
				deviceItems[menuidx].setEnabled(enabled);
			}
		}
	}

	function updateSceneOrGroupStatus(data as Lang.Dictionary<Lang.String,Lang.String or Lang.Number>) {
		var devicedata;
		if (data["Status"].equals("On")) {
			devicedata=WatchUi.loadResource(Rez.Strings.ON);
		} else if (data["Status"].equals("Off")) {
			devicedata=WatchUi.loadResource(Rez.Strings.OFF);
		} else if (data["Status"].equals("Mixed")) {
			devicedata=WatchUi.loadResource(Rez.Strings.MIXED);
		} else {
			devicedata=data["Status"];
		}
		var menuidx=getMenuIndexfromDomoticzIndexforGroupOrScene(data["idx"]);
		if (menuidx!=null) {
			deviceItems[menuidx].setLabel(data["Name"]);
			deviceItems[menuidx].setSubLabel(devicedata);

			if (deviceItems[menuidx] instanceof DomoticzToggleMenuItem) { 
				// we have to update the toggle as well
				var enabled=true;
				if (devicedata.equals(WatchUi.loadResource(Rez.Strings.OFF))) {
					enabled=false;
				}
				deviceItems[menuidx].setEnabled(enabled);
			}
		}
	}

	function onReceive(responseCode as Lang.Number, _data as Lang.Dictionary or Lang.String or Null) as Void {
	    var data=_data as Lang.Dictionary<Lang.String,Lang.Array<Lang.Dictionary>>;

   		Log("onReceive responseCode="+responseCode+" data="+data);
       // Check responsecode
       if (responseCode==200) {
       		// Make sure no error is shown
           	// ShowError=false;  
           	if (data instanceof Dictionary) {
				if (data["status"].equals("OK")) {
	            	if (data["title"].equals("SwitchLight") or 
						data["title"].equals("SwitchScene") or
						data["title"].equals("SetSetpoint")) {
						// a setpoint, scene, group, dimmer of light was switched. Update the device status
			           	deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_COMMAND_EXECUTED_OK));
						delayTimer.start(method(:getCurrentDeviceStatus),delayTime,false); // wait a bit of time before getting new state (sometimes domoticz did not yet process switched state)
					} else if (data["title"].equals("Devices")) {
						if (data["result"]!=null) {
							for (var i=0;i<data["result"].size();i++)
							{
								updateDeviceStatus(data["result"][i]);
							}
						}
					} else if (data["title"].equals("getscenes")) {
						if (data["result"]!=null) {
							for (var i=0;i<data["result"].size();i++)
							{
								updateSceneOrGroupStatus(data["result"][i]);
							}
						}
					} else {
						deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(Rez.Strings.ERROR_INVALID_RESPONSE));
					}
        	    } else {
					Log("not ok, "+data);
					deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_DOMOTICZ_ERROR));
					delayTimer.start(method(:getCurrentDeviceStatus),delayTime,false); // wait a bit of time before getting new state (sometimes domoticz did not yet process switched state)
				} 
            } else {
				deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(Rez.Strings.ERROR_INVALID_RESPONSE));
			}
       } else {
			if (ConnectionErrorMessages[responseCode]==null) 
			{
				// assume general error
				deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(Rez.Strings.ERROR_GENERAL_CONNECTION_ERROR)+" "+responseCode);
			} else {
				deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(ConnectionErrorMessages[responseCode]));
			}
	   }
	   WatchUi.requestUpdate();
	}

    function onReceiveRooms(responseCode as Lang.Number, _data as Lang.Dictionary or Lang.String or Null) as Void {
	   var data=_data as Lang.Dictionary<Lang.String,Lang.Array<Lang.Dictionary>>;

   	   Log("onReceive responseCode="+responseCode+" data="+data);
       // Check responsecode
       if (responseCode==200)
       {
       		// Make sure no error is shown
           	// ShowError=false;
           	if (data instanceof Dictionary) {
				if (data["status"].equals("OK")) {
	            	if (data["title"].equals("getplans")) {
						if (data["result"]!=null) {
							for (var i=0;i<data["result"].size();i++) {
								roomItems.put(data["result"][i]["idx"], new WatchUi.MenuItem(data["result"][i]["Name"], null, data["result"][i]["idx"],{}));
							}
                            _roomscallback.invoke(null);
                        } else {
							_roomscallback.invoke(WatchUi.loadResource(Rez.Strings.STATUS_ROOM_HAS_NO_DEVICES));
						}
                    }else {
						_roomscallback.invoke(WatchUi.loadResource(Rez.Strings.ERROR_INVALID_RESPONSE));
					}
                }else {
					_roomscallback.invoke(WatchUi.loadResource(Rez.Strings.STATUS_DOMOTICZ_ERROR));
				} 
            }else {
				_roomscallback.invoke(WatchUi.loadResource(Rez.Strings.ERROR_INVALID_RESPONSE));
			}
	   } else {
			if (ConnectionErrorMessages[responseCode]==null) 
			{
				// assume general error
				_roomscallback.invoke(WatchUi.loadResource(Rez.Strings.ERROR_GENERAL_CONNECTION_ERROR)+" "+responseCode);
			} else {
				_roomscallback.invoke(WatchUi.loadResource(ConnectionErrorMessages[responseCode]));
			}
	   }
    }    

	function getDeviceType(data as Lang.Dictionary) {
		var DeviceType=DEVICE;
		if (data["Type"].equals("Group")) {
			// it is a group
			DeviceType=GROUP;
		} else if (data["Type"].equals("Scene")) {
			// it is a scene
			DeviceType=SCENE;
		} else if (data["Type"].equals("Setpoint")) {
			// it is a setpoint
			DeviceType=SETPOINT;
		} else {
			// it is a device
			if (data["SwitchType"]!=null) { // it is a switch
				// Set switchtype and correct data if needed
				if (data["SwitchType"].equals("On/Off")) { // switch can be controlled by user
					DeviceType=ONOFF;
				} else if (data["SwitchType"].equals("Selector")) {
					DeviceType=SELECTOR;
				} else if (data["SwitchType"].equals("Dimmer")) {
					DeviceType=DIMMER;
				} else if (data["SwitchType"].equals("Blinds Inverted")) {
					DeviceType=INVERTEDBLINDS;
				} else if (data["SwitchType"].equals("Venetian Blinds US") or data["SwitchType"].equals("Venetian Blinds EU") or ["SwitchType"].equals("Blinds")) { // blinds
					DeviceType=VENBLIND;
				} else if (data["SwitchType"].equals("Push On Button")) { // PushOnButton
					DeviceType=PUSHON;
				} else if (data["SwitchType"].equals("Push Off Button")) { // PushOffButton
					DeviceType=PUSHOFF;
				} else {
					// We didn't recognize the device type, so set as general unswitchable device
					DeviceType=DEVICE;
				}
			} else {
				DeviceType=DEVICE;
			}
		}
		return DeviceType;
	}

	

	function getDeviceData(data as Lang.Dictionary,devicetype as Lang.Number) {
		var DeviceData;

		// set datafield
		if (data["SwitchType"]!=null) {
			// some kind of switch device
			if (devicetype==PUSHOFF) {
				DeviceData=WatchUi.loadResource(Rez.Strings.PUSHOFF);
			} else if (devicetype==PUSHON) {
				DeviceData=WatchUi.loadResource(Rez.Strings.PUSHON);
			} else if (devicetype==SELECTOR) {
				DeviceData="Selector "+data["Data"];
			} else if (data["Data"].equals("On")) {
				// switch is on
				DeviceData=WatchUi.loadResource(Rez.Strings.ON);
			} else if (data["Data"].equals("Off")) {
				// switch is off
				DeviceData=WatchUi.loadResource(Rez.Strings.OFF);
			} else if (data["Data"].equals("Open")) {
				// switch is on
				DeviceData=WatchUi.loadResource(Rez.Strings.OPEN);
			} else if (data["Data"].equals("Closed")) {
				// switch is off
				DeviceData=WatchUi.loadResource(Rez.Strings.CLOSED);
			} else if (data["Data"].equals("Stopped")) {
				// switch is off
				DeviceData=WatchUi.loadResource(Rez.Strings.STOPPED);
			} else if (data["Data"].substring(0,9).equals("Set Level")) {
				DeviceData=data["Data"].substring(10,16);
			} else {
				DeviceData=data["Data"];
			}
		} else if (devicetype==GROUP or devicetype==SCENE) {
			if (data["Status"].equals("On")) {
				DeviceData=WatchUi.loadResource(Rez.Strings.ON);
			} else if (data["Status"].equals("Off")) {
				DeviceData=WatchUi.loadResource(Rez.Strings.OFF);
			} else if (data["Status"].equals("Mixed")) {
				DeviceData=WatchUi.loadResource(Rez.Strings.MIXED);
			} else {
				DeviceData=data["Status"];
			}
		} else if (data["SubType"]!=null) {
			if (data["SubType"].equals("kWh")) {  // kwh device: take the daily counter + usage as data
				DeviceData=data["CounterToday"]+", "+data["Usage"];
			} else if (data["SubType"].equals("Gas")) {  // gas device: take the daily counter as data
				DeviceData=data["CounterToday"];
			} else if (data["SubType"].equals("Energy")) { // Smart meter: take the daily counters for usage and delivery and add current usage
				DeviceData=data["CounterToday"].substring(0,data["CounterToday"].length()-4)+", "+data["CounterDelivToday"]+", "+data["Usage"];
			} else if (data["SubType"].equals("Text")) { // a text device: make sure max length=25
				if (data["Data"].length()>25) {
					DeviceData=data["Data"].substring(0,24);
				} else {
					DeviceData=data["Data"];
				}
			} else {
				DeviceData=data["Data"];
			}
		} else {
			DeviceData=data["Data"];
		} 
		return DeviceData;
	}
	
	function getLevels(string) as Lang.Dictionary {
		var Levels={};
		var location;
		var levelvalue=-10;

		var options = {
			:fromRepresentation => Su.REPRESENTATION_STRING_BASE64,
			:toRepresentation => Su.REPRESENTATION_STRING_PLAIN_TEXT 
		};
		var plainLevelNames=Su.convertEncodedString(string, options);

		do {
			levelvalue+=10;
			location = plainLevelNames.find("|");
			if (location != null) {
				Levels.put(levelvalue,plainLevelNames.substring(0, location));
				plainLevelNames = plainLevelNames.substring(location + 1, string.length());
			}
		} while (location != null);
		Levels.put(levelvalue,plainLevelNames);

		return Levels;
	}

	function onReceiveDevices(responseCode as Lang.Number, _data as Lang.Dictionary or Lang.String or Null) as Void {
       var data=_data as Lang.Dictionary<Lang.String,Lang.Array<Lang.Dictionary>>;

		Log("OnReceiveDevices, responsdecode "+responseCode+"data: "+data);
       // Check responsecode
       if (responseCode==200)
       {
           	if (data instanceof Dictionary) {
				if (data["status"].equals("OK")) {
					if (data["title"].equals("Devices")) { // Long answer 
						if (data["result"]!=null) {
							deviceItems={};
							deviceIDX=new [data["result"].size()];
			            	for (var i=0;i<data["result"].size();i++) {
								var devicetype = getDeviceType(data["result"][i]);
								var devicedata = getDeviceData(data["result"][i],devicetype);
								// create the menuitem
								var mi;
								var Levels = [];
								if (devicetype==SELECTOR) {
									Levels = getLevels(data["result"][i]["LevelNames"]);
									devicedata=Levels[data["result"][i]["LevelInt"]];
								}
								deviceIDX[i]=data["result"][i]["idx"];
								// if (devicetype==ONOFF or devicetype==GROUP or devicetype==DIMMER) {
								if (toggleDeviceTypes.indexOf(devicetype)>=0) {
									var enabled=true;
									if (devicedata.equals(WatchUi.loadResource(Rez.Strings.OFF))) {
										enabled=false;
									}
									mi=new DomoticzToggleMenuItem(data["result"][i]["Name"],
														devicedata,
														i,
														enabled,
														{ :alignment => WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT },
														devicetype,
														Levels);
								} else {
									mi=new DomoticzMenuItem(data["result"][i]["Name"],
														devicedata,
														i,
														{ :alignment => WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT },
														devicetype,
														Levels);
								}
								// add to menu
								deviceItems.put(i,mi);
		        			}
							_devicescallback.invoke(null);
						} else {
							_devicescallback.invoke(WatchUi.loadResource(Rez.Strings.STATUS_ROOM_HAS_NO_DEVICES));
						}
                    } else {
						_devicescallback.invoke(WatchUi.loadResource(Rez.Strings.STATUS_UNKNOWN_HTTP_RESPONSE));
					}
                }else {
					_devicescallback.invoke(WatchUi.loadResource(Rez.Strings.STATUS_DOMOTICZ_ERROR));
				} 
            }else {
				_devicescallback.invoke(WatchUi.loadResource(Rez.Strings.STATUS_UNKNOWN_HTTP_RESPONSE));
			}
      } else {
			if (ConnectionErrorMessages[responseCode]==null) 
			{
				// assume general error
				_devicescallback.invoke(WatchUi.loadResource(Rez.Strings.ERROR_GENERAL_CONNECTION_ERROR)+" "+responseCode);
			} else {
				_devicescallback.invoke(WatchUi.loadResource(ConnectionErrorMessages[responseCode]));
			}
	   }
    }   
}