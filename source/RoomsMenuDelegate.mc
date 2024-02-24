using Toybox.WatchUi;

class RoomsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }
    
  	function onSelect(item) {
  		var id=item.getId();
        Log("Item is "+id);
	}

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (fromGlance) {
            exitApplication=true;
            Log("Exitapplication=true");
        } else {
            Log("Exitapplication=false");
        }
    }
    
}	