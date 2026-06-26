import Toybox.Lang;
import Toybox.WatchUi;

class mvgFavoriteDelegate extends WatchUi.BehaviorDelegate {

    private var _view as mvgFavoriteView;

    function initialize(view as mvgFavoriteView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var index = _view.getSelectedIndex();
        var favs = _view.getFavorites();
        if (favs == null || index >= favs.size()) {
            return true;
        }

        var station = favs[index] as Dictionary;
        var menuView = new mvgStationMenuView(station);
        // Pass a refresh callback so the list reloads after removal
        var menuDelegate = new mvgStationMenuDelegate(menuView, method(:onFavoritesChanged));

        WatchUi.pushView(menuView, menuDelegate, WatchUi.SLIDE_UP);
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

    // Called by station menu after a station is removed from favorites
    function onFavoritesChanged() as Void {
        _view.loadFavorites();
    }
}
