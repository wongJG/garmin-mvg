import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Reusable station action menu — shown when selecting a station
// from Favorites or Nearby list. Pushed as a sub-view on top of the list.
class mvgStationMenuView extends WatchUi.View {

    private var _station as Dictionary;
    private var _selectedIndex as Number = 0;


    private const ITEM_COUNT = 2;

    function initialize(station as Dictionary) {
        View.initialize();
        _station = station;
    }

    function onLayout(dc as Dc) as Void { }

    // Force a redraw after the push animation completes — onUpdate during
    // the slide transition may be discarded by the firmware render pipeline.
    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var titleHeight = (height * 0.20).toNumber();

        // --- Background ---
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // --- Title bar ---
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, width, titleHeight);

        var stationName = _station["name"];
        if (!(stationName instanceof String)) { stationName = "Station"; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2, titleHeight / 2,
            Graphics.FONT_SMALL,
            stationName,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Menu items ---
        var itemStartY = titleHeight;
        var itemHeight = (height - titleHeight) / ITEM_COUNT;

        var fav = isFavorite();
        var favLabel = fav
            ? WatchUi.loadResource(Rez.Strings.station_remove_favorite) as String
            : WatchUi.loadResource(Rez.Strings.station_add_favorite) as String;
        var deptLabel = WatchUi.loadResource(Rez.Strings.station_departures) as String;

        var items = [deptLabel, favLabel];

        for (var i = 0; i < ITEM_COUNT; i++) {
            var y = itemStartY + (i * itemHeight);

            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.fillRectangle(0, y, width, itemHeight);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRectangle(0, y, width, itemHeight);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }

            dc.drawText(
                width / 2, y + itemHeight / 2,
                Graphics.FONT_MEDIUM,
                items[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    function setSelectedIndex(index as Number) as Void {
        _selectedIndex = index;
        WatchUi.requestUpdate();
    }

    function getSelectedIndex() as Number { return _selectedIndex; }
    function getStation() as Dictionary { return _station; }
    function isFavorite() as Boolean { return mvgFavorites.isFavorite(_station); }
}
