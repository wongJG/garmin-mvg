import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class mvgStationMenuDelegate extends WatchUi.BehaviorDelegate {

    private var _menuView as mvgStationMenuView;
    private var _onRemoved as Method() as Void?;

    // _onRemoved is an optional callback invoked after the station is removed
    // from favorites — lets the parent view refresh its list.
    function initialize(menuView as mvgStationMenuView, onRemoved as Method() as Void?) {
        BehaviorDelegate.initialize();
        _menuView = menuView;
        _onRemoved = onRemoved;
    }

    function onSelect() as Boolean {
        var index = _menuView.getSelectedIndex();
        var station = _menuView.getStation();

        if (index == 0) {
            // Persist as last viewed station for the glance view
            mvgLastStation.saveLastStation(station);

            // Push departure view for this station
            var globalId = station["globalId"] as String;
            var name = station["name"] as String;
            var depView = new mvgDepartureView(globalId, name);
            var depDelegate = new mvgDepartureDelegate(depView);
            WatchUi.pushView(depView, depDelegate, WatchUi.SLIDE_UP);
        } else if (index == 1) {
            // Toggle favorite — refresh label before popping so the
            // updated text is visible during the slide-down animation.
            if (_menuView.isFavorite()) {
                mvgFavorites.removeFavorite(station);
                if (_onRemoved != null) {
                    _onRemoved.invoke();
                }
            } else {
                mvgFavorites.addFavorite(station);
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onNextPage() as Boolean {
        if (_menuView.getSelectedIndex() < 1) {
            _menuView.setSelectedIndex(_menuView.getSelectedIndex() + 1);
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        if (_menuView.getSelectedIndex() > 0) {
            _menuView.setSelectedIndex(_menuView.getSelectedIndex() - 1);
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
