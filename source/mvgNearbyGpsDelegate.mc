import Toybox.Lang;
import Toybox.WatchUi;

class mvgNearbyGpsDelegate extends WatchUi.BehaviorDelegate {

    private var _view as mvgNearbyGpsView;

    function initialize(view as mvgNearbyGpsView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var useEvent = (_view.getSelectedIndex() == 0);
        _view.getNearbyView().startLoading(useEvent);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onNextPage() as Boolean {
        if (_view.getSelectedIndex() < 1) {
            _view.setSelectedIndex(1);
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        if (_view.getSelectedIndex() > 0) {
            _view.setSelectedIndex(0);
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
