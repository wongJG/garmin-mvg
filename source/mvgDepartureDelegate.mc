import Toybox.Lang;
import Toybox.WatchUi;

class mvgDepartureDelegate extends WatchUi.BehaviorDelegate {

    private var _view as mvgDepartureView;

    function initialize(view as mvgDepartureView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        // TODO: detail view for a specific departure (future)
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
