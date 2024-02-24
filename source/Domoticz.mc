using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.StringUtil as Su;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.WatchUi;


// global vas which can be used by all classes


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
    var _roomscallback;
	var _devicescallback;
    var roomItems = {};  // will contain the objects with the menu items of the rooms
    var deviceItems = {};  // will contain the objects with the menu items of the devices

    public function initialize()
    {
        // put init code here
    }

    public function populateRooms(callbackhandler)
    {
        _roomscallback=callbackhandler;
        makeWebRequest(GETROOMS,null);
    }

	public function populateDevices(callbackhandler, currentRoom) {
		Log("Currentroom is "+currentRoom);
		_devicescallback=callbackhandler;
		makeWebRequest(GETDEVICES,currentRoom);
	}

    function makeWebRequest(action,idx) {
		// initialize vars
		var url;
		var Domoticz_Protocol;
		var params = {};
		var options = {};

		Log("idx = "+idx);

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

		if (App.getApp().getProperty("PROP_USERNAME").length()==0) {
			params={};
			options={
				:headers => {
					"Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
				}
			};
		} else {
			params={};
			// Log("Basic "+App.getApp().getProperty("PROP_USERNAME")+":"+App.getApp().getProperty("PROP_PASSWORD"));
			options = {
				:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
				:headers => {
					"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
					"Authorization" => "Basic "+Su.encodeBase64(App.getApp().getProperty("PROP_USERNAME")+":"+App.getApp().getProperty("PROP_PASSWORD"))
				}
	        };
			
		}

    	// create url
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
		// Make the reqsetpoiuest
		Log("Calling "+url+"with params "+params);
        Comm.makeWebRequest(
            url,
			params,
			options,
             method(:onReceive)
	     );  
	}

    function onReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
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
								Log("Adding "+data["result"][i]["Name"]+"with index "+data["result"][i]["idx"]+" on index "+i);
								roomItems.put(data["result"][i]["idx"], new WatchUi.MenuItem(data["result"][i]["Name"], null, data["result"][i]["idx"],{}));
							}
                            _roomscallback.invoke(null);
                        } else {
							_roomscallback.invoke("invalid domoticz response");
						}
					} else if (data["title"].equals("getdevices")) {
						if (data["result"]!=null) {
							Log("Getting the devices");
							deviceItems={};
			            	for (var i=0;i<data["result"].size();i++) {
								Log("Adding "+data["result"][i]["Name"]+"with index "+data["result"][i]["idx"]+" on index "+i);
								var mi=new WatchUi.MenuItem(data["result"][i]["Name"],WatchUi.loadResource(Rez.Strings.STATUS_DEVICE_STATUS_LOADING),data["result"][i]["idx"],{});
								deviceItems.put(data["result"][i]["idx"],mi);
								/*
			            		// Check if it is a device or a scene
	       						DevicesIdx[i]=data["result"][i]["devidx"];
	       						DevicesData[i]=Ui.loadResource(Rez.Strings.STATUS_DEVICE_STATUS_LOADING);
			            		if (data["result"][i]["type"]==0) {
		       						DevicesName[i]=data["result"][i]["Name"];
		       						DevicesType[i]=DEVICE;
		            			} else {
		       						DevicesName[i]=data["result"][i]["Name"].substring(8,data["result"][i]["Name"].length());
			       					DevicesType[i]=SCENE; // can be scene or group, but this will be corrected when the def devices is loaded
		   						}*/	
		        			}
						}
                    }else {
						_roomscallback.invoke("unknown domoticz response");
					}
                }else {
					_roomscallback.invoke("Domoticz Error");
				} 
            }else {
				_roomscallback.invoke("Invalid domoticz response");
			}
       }else {
			_roomscallback.invoke("HTTP Error "+responseCode);
	   }
    }   
}