using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.StringUtil as Su;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.WatchUi;


// global vars which can be used by all classes


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
    public var roomItems as Lang.Dictionary = {};  // will contain the objects with the menu items of the rooms
    public var deviceItems as Lang.Dictionary = {};  // will contain the objects with the menu items of the devices
	private var _roomscallback;
	private var _devicescallback;
	private var currentDevice;



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
        // put init code here
    }

    public function populateRooms(callbackhandler)
    {
        _roomscallback=callbackhandler;
        makeWebRequest(GETROOMS,null,method(:onReceiveRooms));
    }

	public function populateDevices(callbackhandler, currentRoom) {
		_devicescallback=callbackhandler;
		makeWebRequest(GETDEVICES,currentRoom,method(:onReceiveAllDevices));
	}

	public function switchOnOffDevice(index, state) {
		// function to switch device. state = true means "on", false means "off"

		// remember device
		currentDevice=index;
		if (state) {
			// we have to switch on
			deviceItems[index].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_SWITCHING_ON));
			WatchUi.requestUpdate();
			makeWebRequest(SENDONCOMMAND,index,method(:onReceive));
		} else {
			deviceItems[index].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_SWITCHING_OFF));
			WatchUi.requestUpdate();
		    makeWebRequest(SENDOFFCOMMAND,index,method(:onReceive)); 
		}
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

		Log("idx = "+idx);

    	// populate parameters;
    	if (action==GETDEVICES) {
			/*
			// old: get just the deviceid's, maybe reuse for low mem devices 
	    	params.put("type","command");
	    	params.put("param","getplandevices");
	    	params.put("idx",idx); */
			// https://domoticz url/json.htm?type=command&param=getdevices&filter=all&used=true&favorite=0&order=[Order]&plan=<planid>
			params.put("type","command");
	    	params.put("param","getdevices");
	    	params.put("filter","all");
			params.put("used","true");
			params.put("favorite",0);
			params.put("order","[Order]");
			params.put("plan",idx);
    	}	else if (action==GETDEVICESTATUS) {
    		params.put("type","devices");
    		params.put("rid",idx);
    	}	else if (action==GETSCENESTATUS) {
    		params.put("type","scenes");
    	}	else if (action==GETROOMS) {
    		params.put("type","plans");
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

	function onReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
   		Log("onReceive responseCode="+responseCode+" data="+data);
       // Check responsecode
       if (responseCode==200) {
       		// Make sure no error is shown
           	// ShowError=false;
           	if (data instanceof Dictionary) {
				if (data["status"].equals("OK")) {
	            	if (data["title"].equals("SwitchLight")) {
						// a scene, group of light was switched. Update the device status
			           	deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_COMMAND_EXECUTED_OK));
                    } else {
						deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(Rez.Strings.ERROR_INVALID_RESPONSE));
					}
        	    } else {
					deviceItems[currentDevice].setSubLabel(WatchUi.loadResource(Rez.Strings.STATUS_DOMOTICZ_ERROR));
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

    function onReceiveRooms(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
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

	function onIconMenuItemDraw(idx) {
		Log("OnIconMenuItemDraw was called for "+idx);
	}

	function getDeviceType(data as Lang.Dictionary) {
		var DeviceType=DEVICE;
		if (data["Type"].equals("Group")) {
			// it is a group
			Log(data["Name"]+" is a group");
			DeviceType=GROUP;
		} else if (data["Type"].equals("Scene")) {
			// it is a scene
			Log(data["Name"]+" is a scene");
			DeviceType=SCENE;
		} else {
			// it is a device
			if (data["SwitchType"]!=null) { // it is a switch
				// Set switchtype and correct data if needed
				if (data["SwitchType"].equals("On/Off")) { // switch can be controlled by user
					DeviceType=ONOFF;
					Log(data["Name"]+" is a onoff");
				} else if (data["SwitchType"].equals("Selector")) {
					DeviceType=SELECTOR;
					Log(data["Name"]+" is a selector");
				} else if (["SwitchType"].equals("Dimmer")) {
					DeviceType=DIMMER;
					Log(data["Name"]+" is a dimmer");
				} else if (["SwitchType"].equals("Blinds Inverted")) {
					DeviceType=INVERTEDBLINDS;
					Log(data["Name"]+" is a invertedblinds");
				} else if (["SwitchType"].equals("Venetian Blinds US") or data["SwitchType"].equals("Venetian Blinds EU") or ["SwitchType"].equals("Blinds")) { // blinds
					DeviceType=VENBLIND;
					Log(data["Name"]+" is a venblind");
				} else if (["SwitchType"].equals("Push On Button")) { // PushOnButton
					DeviceType=PUSHON;
					Log(data["Name"]+" is a pushon");
				} else if (["SwitchType"].equals("Push Off Button")) { // PushOffButton
					DeviceType=PUSHOFF;
					Log(data["Name"]+" is a pushoff");
				} else if (["SubType"].equals("SetPoint")) {
					DeviceType=SETPOINT;
					Log(data["Name"]+" is a setpoint");
				} else {
					// We didn't recognize the device type, so set as general unswitchable device
					DeviceType=DEVICE;
					Log(data["Name"]+" is a  generic device");
				}
			} else {
				DeviceType=DEVICE;
				Log(data["Name"]+" is a device (skipped flow)");
			}
		}
		return DeviceType;
	}

	

	function getDeviceData(data as Lang.Dictionary,devicetype as Lang.Number) {
		var DeviceData;

		// set datafield
		if (devicetype==PUSHOFF) {
			DeviceData=WatchUi.loadResource(Rez.Strings.PUSHOFF);
		} else if (devicetype==PUSHON) {
			DeviceData=WatchUi.loadResource(Rez.Strings.PUSHON);
		} else if (devicetype==SELECTOR) {
			DeviceData="Selector "+data["Data"];
			// updateLevels(data["result"][0]["LevelNames"]);
			// Log(Levels);
			// DeviceData=Levels[data["result"][0]["LevelInt"]];
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
			// Log("Dimmer Level");
			// dimmer level
			DeviceData=data["Data"].substring(10,16);
		} else {
			DeviceData=data["Data"];
		}
		return DeviceData;
	}
	
	function getLevels(string) {
		Levels={};
		var location;
		var levelvalue=-10;

		var options = {
			:fromRepresentation => Su.REPRESENTATION_STRING_BASE64,
			:toRepresentation => Su.REPRESENTATION_STRING_PLAIN_TEXT 
		};
		var plainLevelNames=Su.convertEncodedString(string, options);
		Log("Levelnames = "+plainLevelNames);

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

	function onReceiveAllDevices(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
		Log("OnReceiveAllDevices, responsdecode "+responseCode+"data: "+data);
       // Check responsecode
       if (responseCode==200)
       {
       		// Make sure no error is shown
           	// ShowError=false;
           	if (data instanceof Dictionary) {
				if (data["status"].equals("OK")) {
					if (data["title"].equals("GetPlanDevices")) {
						if (data["result"]!=null) {
							deviceItems={};
			            	for (var i=0;i<data["result"].size();i++) {
								var devicetype=getDeviceType(data["result"][i]);
								var devicedata=getDeviceData(data["result"][i],devicetype);
								Log(data["result"][i]["Name"]+" is a "+devicetype);
								// create the menuitem
								var mi=new DomoticzIconMenuItem(data["result"][i]["Name"],
														devicedata,
														data["result"][i]["idx"],
														new DomoticzIcon(data["result"][i]["idx"]),
														{},
														devicetype);
								// add to menu
								deviceItems.put(data["result"][i]["idx"],mi);						
		        			}
							_devicescallback.invoke(null);
						} else {
							_devicescallback.invoke(WatchUi.loadResource(Rez.Strings.STATUS_ROOM_HAS_NO_DEVICES));
						}
					} else if (data["title"].equals("Devices")) { // Long answer 
						if (data["result"]!=null) {
							deviceItems={};
			            	for (var i=0;i<data["result"].size();i++) {
								// Determine if it's a scene
								var devicetype=getDeviceType(data["result"][i]);
								var devicedata = getDeviceData(data["result"][i],devicetype);
								// create the menuitem
								var mi;
								if (devicetype==ONOFF or devicetype==SELECTOR){
									var enabled = false;
									var Levels = [];
									if (devicetype==ONOFF) {
										enabled=false;
										if (data["result"][i]["Status"].equals("On")) {
											enabled=true;
										} 
									} else if (devicetype==SELECTOR) {
										Log(data["result"][i]);
										Levels = getLevels(data["result"][i]["LevelNames"]);
										devicedata=Levels[data["result"][i]["LevelInt"]];
										if (data["result"][i]["LevelInt"]>0) {
											enabled=true;
										}
									}
									mi=new DomoticzToggleMenuItem(data["result"][i]["Name"],
														devicedata,
														data["result"][i]["idx"],
														enabled,
														{:alignment => WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT},
														devicetype,
														Levels);
								} else {
									mi=new DomoticzIconMenuItem(data["result"][i]["Name"],
														devicedata,
														data["result"][i]["idx"],
														new DomoticzIcon(data["result"][i]["idx"]),
														{},
														devicetype);
								}
								// add to menu
								deviceItems.put(data["result"][i]["idx"],mi);
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
       }else {
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