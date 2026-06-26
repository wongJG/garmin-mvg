import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class mvgGlanceView extends WatchUi.GlanceView {

    private var _stationName as String = "";
    private var _hasData as Boolean = false;
    private var _loading as Boolean = false;

    // Latest departure info
    private var _depLabel as String = "";
    private var _depDestination as String = "";
    private var _depTime as String = "";
    private var _depDelayMin as Number = 0;
    private var _depCancelled as Boolean = false;
    private var _depTransportType as String = "";

    function initialize() {
        GlanceView.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // Layout handled in onUpdate
    }

    function onShow() as Void {
        var station = mvgLastStation.getLastStation();
        var name = station != null ? station["name"] as String : null;

        if (name == null || (name instanceof String && name.length() == 0)) {
            _stationName = WatchUi.loadResource(Rez.Strings.AppName) as String;
            _hasData = false;
            _loading = false;
            WatchUi.requestUpdate();
            return;
        }

        _stationName = name;

        // Only fetch if we haven't loaded yet
        if (!_loading && !_hasData) {
            loadLatestDeparture(station["globalId"] as String);
        }
    }

    // --- API call (same endpoint as mvgDepartureView) ---

    function loadLatestDeparture(globalId as String?) as Void {
        if (globalId == null) {
            _hasData = false;
            _loading = false;
            WatchUi.requestUpdate();
            return;
        }

        _loading = true;
        WatchUi.requestUpdate();

        var encodedId = encodeGlobalId(globalId);
        var url = "https://www.mvg.de/api/bgw-pt/v3/departures" +
                  "?globalId=" + encodedId +
                  "&limit=3" +
                  "&offsetInMinutes=0";

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => { "Accept" => "application/json" },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        System.println("Glance departures: " + url);
        Communications.makeWebRequest(url, null, options, method(:onApiResponse));
    }

    private function encodeGlobalId(id as String) as String {
        var result = "";
        var len = id.length();
        for (var i = 0; i < len; i++) {
            var ch = id.substring(i, i + 1);
            if (ch.equals(":")) {
                result = result + "%3A";
            } else {
                result = result + ch;
            }
        }
        return result;
    }

    function onApiResponse(responseCode as Number, data as Null or Dictionary or String) as Void {
        _loading = false;

        if (responseCode == 200 && data != null) {
            var departures = data as Array<Dictionary>;
            if (departures != null && departures.size() > 0) {
                // Use the first departure
                var dep = departures[0] as Dictionary;
                _depLabel = dep["label"] as String;
                _depDestination = dep["destination"] as String;
                _depTransportType = dep["transportType"] as String;
                _depDelayMin = dep["delayInMinutes"] as Number;
                _depCancelled = dep["cancelled"] as Boolean;

                var plannedMs = dep["plannedDepartureTime"] as Number;
                _depTime = formatDepartureTime(plannedMs, _depCancelled);
                _hasData = true;
            } else {
                _hasData = false;
            }
        } else {
            _hasData = false;
            System.println("Glance err: " + responseCode.toString());
        }
        WatchUi.requestUpdate();
    }

    // --- Drawing ---

    function onUpdate(dc as Dc) as Void {
        GlanceView.onUpdate(dc);

        var width = dc.getWidth();
        var height = dc.getHeight();

        // Background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Compact layout for glance view
        var margin = 4;
        var labelY = margin + 6;
        var badgeY = labelY + 16;

        // --- Station name (top, centered, small) ---
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);

        // Truncate long station names
        var displayName = _stationName;
        var maxNameChars = (width / 6).toNumber();
        if (maxNameChars < 3) { maxNameChars = 3; }
        if (displayName.length() > maxNameChars) {
            displayName = displayName.substring(0, maxNameChars - 1) + "…";
        }

        dc.drawText(
            width / 2, labelY,
            Graphics.FONT_XTINY,
            displayName,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (!_hasData && !_loading) {
            // No last station or no departures — show hint
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                width / 2, height / 2 + 4,
                Graphics.FONT_XTINY,
                "Open to start",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            return;
        }

        if (_loading) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                width / 2, height / 2 + 4,
                Graphics.FONT_XTINY,
                "…",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            return;
        }

        // --- Line badge ---
        var badgeW = _depLabel.length() * 7 + 8;
        if (badgeW < 20) { badgeW = 20; }
        var badgeH = 16;
        var badgeX = margin;

        var typeColor = getTransportColor(_depTransportType);
        if (_depCancelled) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        } else {
            dc.setColor(typeColor, Graphics.COLOR_BLACK);
        }
        dc.fillRectangle(badgeX, badgeY, badgeW, badgeH);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            badgeX + badgeW / 2, badgeY + badgeH / 2,
            Graphics.FONT_TINY,
            _depLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Destination (right of badge, null-safe before accessing .length()) ---
        var destX = badgeX + badgeW + 4;
        var destMaxW = width - destX - margin - 70;
        var displayDest = _depDestination;

        var maxDestChars = (destMaxW / 8).toNumber();
        if (maxDestChars < 3) { maxDestChars = 3; }
        if (displayDest.length() > maxDestChars) {
            displayDest = displayDest.substring(0, maxDestChars - 1) + "…";
        }

        if (_depCancelled) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(
            destX, badgeY + badgeH / 2,
            Graphics.FONT_TINY,
            displayDest,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Time (right-aligned, on same row as destination) ---
        var timeX = width - margin;
        if (_depCancelled) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(
            timeX, badgeY + badgeH / 2,
            Graphics.FONT_TINY,
            _depTime,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );

    }

    // --- Helpers (mirror mvgDepartureView) ---

    private function formatDepartureTime(plannedMs as Number?, cancelled as Boolean?) as String {
        if (cancelled) { return "--"; }
        if (plannedMs == null) { return "?"; }

        var nowSec = Time.now().value();
        var plannedSec = plannedMs / 1000;
        var diffMin = ((plannedSec - nowSec) / 60).toNumber();

        if (diffMin <= 0) {
            return "now";
        } else if (diffMin < 60) {
            return diffMin.format("%d") + "m";
        } else {
            var moment = new Time.Moment(plannedSec.toNumber());
            var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
            return info.hour.format("%02d") + ":" + info.min.format("%02d");
        }
    }

    private function getTransportColor(type as String?) as Number {
        if (type == null) { return Graphics.COLOR_LT_GRAY; }
        if (type.equals("UBAHN")) { return Graphics.COLOR_BLUE; }
        if (type.equals("TRAM"))  { return Graphics.COLOR_GREEN; }
        if (type.equals("BUS"))   { return Graphics.COLOR_ORANGE; }
        if (type.equals("SBAHN")) { return Graphics.COLOR_DK_GREEN; }
        return Graphics.COLOR_LT_GRAY;
    }
}
