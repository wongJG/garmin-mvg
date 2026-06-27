import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class mvgDelegate extends WatchUi.BehaviorDelegate {


    private var _view as mvgView;

    function initialize(view as mvgView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var selected = _view.getSelectedIndex();

        if (selected == 0) {
            // Favorite selected
            onFavoriteSelected();
        } else if (selected == 1) {
            // Nearby selected
            onNearbySelected();

        }

        return true;
    }

    function onNextPage() as Boolean {
        // Scroll down through menu items
        var current = _view.getSelectedIndex();
        if (current < 1) {
            _view.setSelectedIndex(current + 1);
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        // Scroll up through menu items
        var current = _view.getSelectedIndex();
        if (current > 0) {
            _view.setSelectedIndex(current - 1);
        }
        return true;
    }

    // --- Navigation handlers (placeholders — detail added later) ---

    function onNearbySelected() as Void {
        var view = new mvgNearbyView();
        WatchUi.pushView(view, new mvgNearbyDelegate(view), WatchUi.SLIDE_UP);
    }

    function onFavoriteSelected() as Void {
        var view = new mvgFavoriteView();
        WatchUi.pushView(view, new mvgFavoriteDelegate(view), WatchUi.SLIDE_UP);
    }
}
