import Toybox.Application.Storage;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.StringUtil as Su;
using Toybox.Timer as Timer;
using Toybox.Lang;


(:glance)
class GarmoticzGlanceView extends Ui.GlanceView {

  // Statustexts
  var StatusText="Checking connection";
  var StatusColor=Graphics.COLOR_LT_GRAY;

	// Timer to prevent too many url's when scrolling through devices
	var delayTimer;
	const delayTime= 10 * 1000; // number of milliseconds before status is requested

  // define functions for debugging on console which is not executed in release version
  (:debug) function Log(message) {
    System.println(message);
  }

  (:release) function Log(message) {
    // do nothing
  }

  // Receive the data from the web request
  function onReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void
  {
    Refreshing=false; // data received
    // Log(Toybox.System.println("onReceive responseCode="+responseCode+" data="+data));
    Log("onReceive responseCode="+responseCode+" data="+data);

    // Check responsecode
    if (responseCode==200)
    {
      // Make sure no error is shown
      // ShowError=false;
      if (data instanceof Dictionary) {
        if (data["status"].equals("OK")) {
          if (data["title"].equals("GetVersion")) {
            StatusText="OK ("+data["version"]+")";
            StatusColor=Graphics.COLOR_GREEN;
        } else {
            StatusText="Invalid Response";
            StatusColor=Graphics.COLOR_RED;
          }
        } else {
          StatusText="Domoticz Error";
          StatusColor=Graphics.COLOR_RED;
        }
      }
    } else {
      StatusText="HTTP Error "+responseCode;
      StatusColor=Graphics.COLOR_RED;
    }
    // Let's update the screen
    Ui.requestUpdate();

    // Set timer for next check
    delayTimer.start(method(:CheckConnection),delayTime,false);
  }

  function CheckConnection() {
    // initialize vars
    var url;
    var Domoticz_Protocol;
    var params = {};
    var options = {};

    // set status
    StatusText="Checking Connection";
    StatusColor=Graphics.COLOR_LT_GRAY;

    // Let's update the screen
    Ui.requestUpdate();


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
      options={
        :headers => {
          "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
        }
      };
    } else {
      Log("Basic "+App.getApp().getProperty("PROP_USERNAME")+":"+App.getApp().getProperty("PROP_PASSWORD"));
      options = {
        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        :headers => {
          "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
          "Authorization" => "Basic "+Su.encodeBase64(App.getApp().getProperty("PROP_USERNAME")+":"+App.getApp().getProperty("PROP_PASSWORD"))
        }
      };
    }
    Log (url);
    params.put("type","command");
    params.put("param","getversion");

    Log("url="+url+",params="+params);

    // Make the reqsetpoiuest
    Comm.makeWebRequest(
        url,
        params,
        options,
        method(:onReceive)
    );
  }
     
  function initialize() {
    // call the parent
    GlanceView.initialize();

    // Initialize the timer
    delayTimer=new Timer.Timer();

    // start checking the connection
    CheckConnection();
  }

  function onUpdate(dc) {
      dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
      var Text="Domoticz";
      dc.drawText(0, 
                  dc.getHeight()/3, 
                  Graphics.FONT_TINY,
                  Text, 
                  Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
      dc.drawText(dc.getFontHeight(Graphics.FONT_TINY), 
                  dc.getHeight()/3*2, 
                  Graphics.FONT_XTINY,
                  StatusText,
                  Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);  
      dc.setColor(StatusColor,StatusColor);
      dc.fillCircle(dc.getFontHeight(Graphics.FONT_TINY)/2, dc.getHeight()/3*2, dc.getFontHeight(Graphics.FONT_TINY)*2/10);  
  }
}