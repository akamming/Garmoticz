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
    var roomItems = {};  // will contain the objects with the menu items of the rooms
    var deviceItems = {};  // will contain the objects with the menu items of the devices
	var _roomscallback;
	var _devicescallback;

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
		Log("Currentroom is "+currentRoom);
		_devicescallback=callbackhandler;
		makeWebRequest(GETDEVICES,currentRoom,method(:onReceiveDevices));
	}

	function getUrl() {
		var url;
		var Domoticz_Protocol;

		if (App.getApp().getProperty("PROP_PROTOCOL")==0) {
			Domoticz_Protocol="http";
		} else {
			Domoticz_Protocol="https";
		}

		url=Domoticz_Protocol+"://"+App.getApp().getProperty("PROP_ADRESS")+":"+App.getApp().getProperty("PROP_PORT");
		if(App.getApp().getProperty("PROP_PATH")!="") {
			url += App.getApp().getProperty("PROP_PATH");
		}
		url += "/json.htm";
		return url;
	}

	function getOptions() {
		var options;

		if (App.getApp().getProperty("PROP_USERNAME").length()==0) {
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
					"Authorization" => "Basic "+Su.encodeBase64(App.getApp().getProperty("PROP_USERNAME")+":"+App.getApp().getProperty("PROP_PASSWORD"))
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
	    	params.put("type","command");
	    	params.put("param","getplandevices");
	    	params.put("idx",idx);
    	}	else if (action==GETDEVICESTATUS) {
    		params.put("type","devices");
    		params.put("rid",DevicesIdx[devicecursor]);
    	}	else if (action==GETSCENESTATUS) {
    		params.put("type","scenes");
    	}	else if (action==GETROOMS) {
    		params.put("type","plans");
    		params.put("order","Order");
    		params.put("used","true");
    	}	else if (action==SENDONCOMMAND) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",DevicesIdx[devicecursor]);
    		params.put("switchcmd","On");
    	}	else if (action==SENDOFFCOMMAND) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",DevicesIdx[devicecursor]);
    		params.put("switchcmd","Off");
    	}	else if (action==SENDSTOPCOMMAND) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",DevicesIdx[devicecursor]);
    		params.put("switchcmd","Stop");
    	}	else if (action==SENDSETPOINT) {
    		params.put("type","command");
    		params.put("param","setsetpoint");
    		params.put("idx",DevicesIdx[devicecursor]);
    		params.put("setpoint",setpoint);
    	}	else if (action==SENDSELECTOR) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",DevicesIdx[devicecursor]);
			if (dimmerlevel==0) {
				params.put("switchcmd","Off");
			} else {
				params.put("switchcmd","Set Level");
				params.put("level",dimmerlevel);
			}
    	}	else if (action==SENDDIMMERVALUE) {
    		params.put("type","command");
    		params.put("param","switchlight");
    		params.put("idx",DevicesIdx[devicecursor]);
    		params.put("switchcmd","Set Level");
    		params.put("level",dimmerlevel);
    	}	else if (action==SWITCHOFFGROUP) {
    		params.put("type","command");
    		params.put("param","switchscene");
    		params.put("idx",DevicesIdx[devicecursor]);
    		params.put("switchcmd","Off");
    	}	else if (action==SWITCHONGROUP) {
       		params.put("type","command");
    		params.put("param","switchscene");
    		params.put("idx",DevicesIdx[devicecursor]);
    		params.put("switchcmd","On");
    	} else {
    		url="unknown url";
        }
		// Make the request
		 callUrl(url,options,params,callback);
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
                            Log("Getting the rooms");
							roomItems={};
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
       }else {
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
	
	function onReceiveDevices(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
   		Log("onReceive responseCode="+responseCode+" data="+data);
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
								// Determine if it's a scene
								var devicetype;
			            		if (data["result"][i]["type"]==0) {
		       						devicetype=DEVICE;
		            			} else {
									devicetype=SCENE; // can be scene or group, but this will be corrected when the def devices is loaded
		   						}
								// create the menuitem
								var mi=new DomoticzIconMenuItem(data["result"][i]["Name"],
														WatchUi.loadResource(Rez.Strings.STATUS_DEVICE_STATUS_LOADING),
														data["result"][i]["idx"],
														new DomoticzIcon(data["result"][i]["idx"],method(:onIconMenuItemDraw)),
														{},
														devicetype);
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