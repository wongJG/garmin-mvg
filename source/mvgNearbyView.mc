import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

class mvgNearbyView extends WatchUi.View {

    // --- State constants ---
    private const STATE_LOADING = 0;
    private const STATE_ERROR   = 1;
    private const STATE_LOADED  = 2;

    // --- Layout constants ---
    private const TITLE_RATIO   = 0.20;   // title bar height as fraction of screen
    private const ITEM_HEIGHT   = 40;     // each station row height in pixels
    private const BADGE_SIZE    = 13;     // transport type badge width/height
    private const BADGE_GAP     = 2;      // gap between badges

    // --- State ---
    private var _state as Number = STATE_LOADING;
    private var _statusMessage as String = "";
    private var _stations as Array<Dictionary> = [];
    private var _selectedIndex as Number = 0;
    private var _topVisibleIndex as Number = 0;

    function initialize() {
        View.initialize();
        _statusMessage = WatchUi.loadResource(Rez.Strings.nearby_searching) as String;
    }

    function onLayout(dc as Dc) as Void {
        // Layout handled in onUpdate
    }

    function onShow() as Void {
        if (_stations.size() == 0 && _state == STATE_LOADING) {
            loadStations();
        }
    }

    // --- GPS + API (called from onShow) ---

    function loadStations() as Void {
        _state = STATE_LOADING;
        _statusMessage = WatchUi.loadResource(Rez.Strings.nearby_searching) as String;
        WatchUi.requestUpdate();

        // Get GPS position; fall back to Munich coordinates in simulator
        var lat = 48.160000;
        var lon = 11.530000;
        var isFallback = true;

        var info = Position.getInfo();
        if (info != null && info.position != null) {
            var deg = info.position.toDegrees();
            var gpsLat = deg[0] as Float;
            var gpsLon = deg[1] as Float;

            lat = gpsLat;
            lon = gpsLon;
            isFallback = false;
        }

        System.println("GPS: " + lat.format("%.6f") + ", " + lon.format("%.6f") +
                       (isFallback ? " (fallback)" : ""));

        // Build MVG API request
        var url = "https://www.mvg.de/api/bgw-pt/v3/stations/nearby" +
                  "?latitude=" + lat.format("%.6f") +
                  "&longitude=" + lon.format("%.6f");

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Accept" => "application/json",
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(url, null, options, method(:onApiResponse));
    }

    // --- API response callback ---
    // Garmin makeWebRequest callback: responseCode=200 is HTTP OK (with parsed JSON data).
    // Negative responseCode = Garmin Communications error:
    //   -1  = BLE_CONNECTION_UNAVAILABLE (phone not connected)
    //   -2  = BLE_QUEUE_FULL (too many pending requests)
    //   -3  = BLE_REQUEST_CANCELLED

    function onApiResponse(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode == 200 && data != null) {
            // MVG API returns JSON array; Communications auto-parses to Array at runtime
            var stations = data as Array<Dictionary>;
            if (stations != null && stations.size() > 0) {
                _stations = stations;
                _state = STATE_LOADED;
                _selectedIndex = 0;
                _topVisibleIndex = 0;
            } else {
                _state = STATE_ERROR;
                _statusMessage = WatchUi.loadResource(Rez.Strings.nearby_no_stations) as String;
            }
        } else {
            // HTTP error from server (4xx, 5xx, etc.)
            _state = STATE_ERROR;
            _statusMessage = WatchUi.loadResource(Rez.Strings.nearby_network_error) as String;
            System.println("HTTP err: " + responseCode.toString());
        }
        WatchUi.requestUpdate();
    }

    // --- Navigation ---

    function scrollDown() as Void {
        if (_stations.size() == 0) { return; }
        if (_selectedIndex < _stations.size() - 1) {
            _selectedIndex++;
            ensureVisible(_selectedIndex);
            WatchUi.requestUpdate();
        }
    }

    function scrollUp() as Void {
        if (_stations.size() == 0) { return; }
        if (_selectedIndex > 0) {
            _selectedIndex--;
            ensureVisible(_selectedIndex);
            WatchUi.requestUpdate();
        }
    }

    private function ensureVisible(index as Number) as Void {
        var visible = visibleCount();
        if (index < _topVisibleIndex) {
            _topVisibleIndex = index;
        } else if (index >= _topVisibleIndex + visible) {
            _topVisibleIndex = index - visible + 1;
        }
    }

    // --- Getters for delegate ---

    function getSelectedIndex() as Number {
        return _selectedIndex;
    }

    function getStations() as Array<Dictionary> {
        return _stations;
    }

    // --- Drawing ---

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var titleHeight = (height * TITLE_RATIO).toNumber();

        // --- Background ---
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // --- Title bar ---
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, width, titleHeight);

        var titleText = WatchUi.loadResource(Rez.Strings.nearby_title) as String;
        if (_state == STATE_LOADED) {
            titleText = titleText + " (" + _stations.size().toString() + ")";
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2, titleHeight / 2,
            Graphics.FONT_SMALL,
            titleText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Content ---
        if (_state == STATE_LOADED && _stations.size() > 0) {
            drawStationList(dc, width, height, titleHeight);
        } else if (_state == STATE_LOADING) {
            drawStatusMessage(dc, width, height, titleHeight, _statusMessage);
        } else {
            // STATE_ERROR
            drawStatusMessage(dc, width, height, titleHeight, _statusMessage);
        }
    }

    // --- Draw station list ---

    private function drawStationList(dc as Dc, width as Number, height as Number, titleHeight as Number) as Void {
        var visible = visibleCount();

        for (var i = 0; i < visible; i++) {
            var stationIndex = _topVisibleIndex + i;
            if (stationIndex >= _stations.size()) {
                break;
            }

            var y = titleHeight + (i * ITEM_HEIGHT);
            var isSelected = (stationIndex == _selectedIndex);

            drawStationRow(dc, width, y, _stations[stationIndex] as Dictionary, isSelected);

            // Separator line between items
            if (i > 0) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.drawLine(10, y, width - 10, y);
            }
        }
    }

    private function drawStationRow(dc as Dc, width as Number, y as Number, station as Dictionary, isSelected as Boolean) as Void {
        // --- Row background ---
        if (isSelected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        }
        dc.fillRectangle(0, y, width, ITEM_HEIGHT);

        // --- Data ---
        var types = station["transportTypes"] as Array<String>;
        var distMeters = station["distanceInMeters"] as Number;
        var distText = formatDistance(distMeters);
        var nameText = station["name"] as String;
        var badgeCount = types != null ? types.size() : 0;
        var rightMargin = 5;
        var distWidth = 45; // ~width of "328m" in FONT_SMALL
        var distX = width - rightMargin;
        var distY = y + (ITEM_HEIGHT / 2);

        // --- Distance (right-aligned) ---
        if (isSelected) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(
            distX, distY,
            Graphics.FONT_SMALL,
            distText,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Transport badges (to the left of distance) ---
        var badgesTotalWidth = badgeCount * (BADGE_SIZE + BADGE_GAP) - BADGE_GAP;
        var badgeStartX = width - rightMargin - distWidth - 10 - badgesTotalWidth;

        for (var b = 0; b < badgeCount; b++) {
            var bx = badgeStartX + b * (BADGE_SIZE + BADGE_GAP);
            var by = y + (ITEM_HEIGHT / 2) - (BADGE_SIZE / 2);

            var typeStr = types[b] as String;
            var typeColor = getTransportColor(typeStr);

            if (isSelected) {
                // Selected row: black badge, white letter
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRectangle(bx, by, BADGE_SIZE, BADGE_SIZE);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            } else {
                // Unselected row: colored badge, white letter
                dc.setColor(typeColor, Graphics.COLOR_BLACK);
                dc.fillRectangle(bx, by, BADGE_SIZE, BADGE_SIZE);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }

            var label = formatTransportLabel(typeStr);
            dc.drawText(
                bx + BADGE_SIZE / 2, by + BADGE_SIZE / 2,
                Graphics.FONT_TINY,
                label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // --- Station name (left-aligned, truncated if too long) ---
        // Estimate available width before badges/distance, then clip to fit.
        // FONT_SMALL ≈ 8px per char; use 9px to be safe.
        var nameMaxWidth = badgeStartX - 55;
        var maxChars = (nameMaxWidth / 9).toNumber();
        var displayName = nameText;
        if (nameText != null && maxChars > 3 && nameText.length() > maxChars) {
            displayName = nameText.substring(0, maxChars - 1) + "…"; // …
        }
        if (isSelected) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(
            10, y + (ITEM_HEIGHT / 2),
            Graphics.FONT_SMALL,
            displayName,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // --- Draw loading / error message ---

    private function drawStatusMessage(dc as Dc, width as Number, height as Number, titleHeight as Number, message as String) as Void {
        var contentY = titleHeight + (height - titleHeight) / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2, contentY,
            Graphics.FONT_SMALL,
            message,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // --- Helpers ---

    private function visibleCount() as Number {
        // fenix7: 260px; title 52px; 208px / 40px = 5 visible items
        return 5;
    }

    private function formatDistance(meters as Number?) as String {
        if (meters == null) { return "?"; }
        if (meters < 1000) {
            return meters.format("%d") + "m";
        } else {
            var km = meters / 1000.0;
            return km.format("%.1f") + "km";
        }
    }

    private function formatTransportLabel(type as String?) as String {
        if (type == null) { return "?"; }
        if (type.equals("UBAHN"))  { return "U"; }
        if (type.equals("TRAM"))   { return "T"; }
        if (type.equals("BUS"))    { return "B"; }
        if (type.equals("SBAHN"))  { return "S"; }
        if (type.length() > 0) { return type.substring(0, 1); }
        return "?";
    }

    private function getTransportColor(type as String?) as Number {
        if (type == null) { return Graphics.COLOR_LT_GRAY; }
        if (type.equals("UBAHN")) { return Graphics.COLOR_BLUE; }
        if (type.equals("TRAM"))  { return Graphics.COLOR_RED; }
        if (type.equals("BUS"))   { return Graphics.COLOR_DK_GREEN; }
        if (type.equals("SBAHN")) { return Graphics.COLOR_GREEN; }
        return Graphics.COLOR_LT_GRAY;
    }
}
