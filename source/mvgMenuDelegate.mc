import Toybox.Lang;
import Toybox.WatchUi;

class mvgMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId() as Symbol;

        if (id == :settings) {
            // TODO: Open settings
        } else if (id == :about) {
            // TODO: Show about info
        }

        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
