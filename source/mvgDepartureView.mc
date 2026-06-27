import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class mvgDepartureView extends WatchUi.View {

    // --- State ---
    private const STATE_LOADING = 0;
    private const STATE_ERROR   = 1;
    private const STATE_LOADED  = 2;

    // --- Layout ---
    private const TITLE_RATIO = 0.20;
    private const ITEM_HEIGHT = 40;

    // --- State ---
    private var _globalId as String;
    private var _stationName as String;
    private var _state as Number = STATE_LOADING;
    private var _statusMessage as String = "";
    private var _departures as Array<Dictionary> = [];
    private var _selectedIndex as Number = 0;
    private var _topVisibleIndex as Number = 0;

    function initialize(globalId as String, stationName as String) {
        View.initialize();
        _globalId = globalId;
        _stationName = stationName;
        _statusMessage = WatchUi.loadResource(Rez.Strings.departure_loading) as String;
    }

    function onLayout(dc as Dc) as Void { }

    function onShow() as Void {
        if (_departures.size() == 0 && _state == STATE_LOADING) {
            loadDepartures();
        }
    }

    // --- API ---

    function loadDepartures() as Void {
        _state = STATE_LOADING;
        _statusMessage = WatchUi.loadResource(Rez.Strings.departure_loading) as String;
        WatchUi.requestUpdate();

        var encodedId = encodeGlobalId(_globalId);
        var url = "https://www.mvg.de/api/bgw-pt/v3/departures" +
                  "?globalId=" + encodedId +
                  "&limit=10" +
                  "&offsetInMinutes=0";

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => { "Accept" => "application/json" },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        System.println("Departures: " + url);
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

    // --- Response ---

    function onApiResponse(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode == 200 && data != null) {
            var departures = data as Array<Dictionary>;
            if (departures != null && departures.size() > 0) {
                _departures = departures;
                _state = STATE_LOADED;
                _selectedIndex = 0;
                _topVisibleIndex = 0;
            } else {
                _state = STATE_ERROR;
                _statusMessage = WatchUi.loadResource(Rez.Strings.departure_empty) as String;
            }
        } else {
            _state = STATE_ERROR;
            _statusMessage = WatchUi.loadResource(Rez.Strings.nearby_network_error) as String;
            System.println("Departure err: " + responseCode.toString());
        }
        WatchUi.requestUpdate();
    }

    // --- Navigation ---

    function scrollDown() as Void {
        if (_departures.size() == 0) { return; }
        if (_selectedIndex < _departures.size() - 1) {
            _selectedIndex++;
            ensureVisible(_selectedIndex);
            WatchUi.requestUpdate();
        }
    }

    function scrollUp() as Void {
        if (_departures.size() == 0) { return; }
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

    // --- Drawing ---

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var titleHeight = (height * TITLE_RATIO).toNumber();

        // Background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Title bar
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, width, titleHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2, titleHeight / 2,
            Graphics.FONT_SMALL,
            _stationName,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Content
        if (_state == STATE_LOADED && _departures.size() > 0) {
            drawDepartureList(dc, width, height, titleHeight);
        } else {
            drawStatusMessage(dc, width, height, titleHeight, _statusMessage);
        }
    }

    private function drawDepartureList(dc as Dc, width as Number, height as Number, titleHeight as Number) as Void {
        var visible = visibleCount();
        for (var i = 0; i < visible; i++) {
            var idx = _topVisibleIndex + i;
            if (idx >= _departures.size()) { break; }

            var y = titleHeight + (i * ITEM_HEIGHT);
            var isSelected = (idx == _selectedIndex);
            drawDepartureRow(dc, width, y, _departures[idx] as Dictionary, isSelected);

            if (i > 0) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.drawLine(10, y, width - 10, y);
            }
        }
    }

    private function drawDepartureRow(dc as Dc, width as Number, y as Number, dep as Dictionary, isSelected as Boolean) as Void {
        // Row background
        if (isSelected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        }
        dc.fillRectangle(0, y, width, ITEM_HEIGHT);

        var transportType = dep["transportType"] as String;
        var label = dep["label"] as String;
        var destination = dep["destination"] as String;
        var plannedMs = dep["plannedDepartureTime"] as Number;
        var delayMin = dep["delayInMinutes"] as Number;
        var cancelled = dep["cancelled"] as Boolean;

        var rowCenter = y + (ITEM_HEIGHT / 2);

        var hasDelay = !cancelled && delayMin != null && delayMin > 0;

        // --- Line badge (colored by transport type, variable width for "N17" etc.) ---
        var badgeW = label != null ? label.length() * 6 + 8 : 16;
        if (badgeW < 22) { badgeW = 22; }
        var badgeH = 16;
        var badgeX = 10;
        var badgeY = rowCenter - badgeH / 2;
        var typeColor = getTransportColor(transportType);

        if (cancelled) {
            if (isSelected) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            }
        } else if (isSelected) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        } else {
            dc.setColor(typeColor, Graphics.COLOR_BLACK);
        }
        dc.fillRectangle(badgeX, badgeY, badgeW, badgeH);

        // Badge text
        if (isSelected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(
            badgeX + badgeW / 2, rowCenter,
            Graphics.FONT_TINY,
            label != null ? label : "?",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Delay badge (red box, white text) — drawn before time so we can position it ---
        var delayBoxW = 24;
        var delayBoxH = 14;
        var delayBoxX = width - 50 - delayBoxW; // right of time area

        if (hasDelay) {
            var delayText = "+" + delayMin.format("%d");
            var delayBoxY = rowCenter - delayBoxH / 2;

            // Red filled box
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            dc.fillRectangle(delayBoxX, delayBoxY, delayBoxW, delayBoxH);
            // White text
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                delayBoxX + delayBoxW / 2, rowCenter,
                Graphics.FONT_TINY,
                delayText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // --- Destination (left of badge, shortened when delay is shown) ---
        var destX = badgeX + badgeW + 8;
        var rightAreaW = hasDelay ? 98 : 70;
        var destMaxW = width - destX - rightAreaW;

        if (isSelected) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else if (cancelled) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }

        var displayDest = truncateText(destination, destMaxW);
        dc.drawText(
            destX, rowCenter,
            Graphics.FONT_SMALL,
            displayDest,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Time (right-aligned) ---
        var timeX = width - 5;
        var timeText = formatDepartureTime(plannedMs, cancelled);

        if (isSelected) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else if (cancelled) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(
            timeX, rowCenter,
            Graphics.FONT_SMALL,
            timeText,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // --- Loading / error ---

    private function drawStatusMessage(dc as Dc, width as Number, height as Number, titleHeight as Number, message as String) as Void {
        var y = titleHeight + (height - titleHeight) / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2, y,
            Graphics.FONT_SMALL,
            message,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // --- Helpers ---

    private function visibleCount() as Number { return 5; }

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
            var info = Gregorian.info(moment, Time.FORMAT_SHORT);
            return info.hour.format("%02d") + ":" + info.min.format("%02d");
        }
    }

    private function truncateText(text as String?, maxWidth as Number) as String {
        if (text == null) { return ""; }
        // FONT_SMALL ≈ 8px per char; use 9px to be safe
        var maxChars = (maxWidth / 9).toNumber();
        if (maxChars < 3) { maxChars = 3; }
        if (text.length() > maxChars) {
            return text.substring(0, maxChars - 1) + "…"; // …
        }
        return text;
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
