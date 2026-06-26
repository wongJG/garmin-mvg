import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class mvgNearbyDelegate extends WatchUi.BehaviorDelegate {

    private var _view as mvgNearbyView;

    function initialize(view as mvgNearbyView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var index = _view.getSelectedIndex();
        var stations = _view.getStations();
        if (stations != null && index < stations.size()) {
            var station = stations[index] as Dictionary;

            // Push the reusable station menu (mvgStationMenuView checks favorite status itself)
            var menuView = new mvgStationMenuView(station);
            var menuDelegate = new mvgStationMenuDelegate(menuView, null);

            WatchUi.pushView(menuView, menuDelegate, WatchUi.SLIDE_UP);
        }
        return true;
    }

    function onNextPage() as Boolean {
        _view.scrollDown();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.scrollUp();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
