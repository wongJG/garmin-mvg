import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class mvgApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the glance view shown in the widget loop preview
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [ new mvgGlanceView() ];
    }

    // Return the initial view when the widget is opened (tapped)
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new mvgView();
        return [ view, new mvgDelegate(view) ];
    }

}

function getApp() as mvgApp {
    return Application.getApp() as mvgApp;
}