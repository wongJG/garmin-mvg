import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class mvgFavoriteView extends WatchUi.View {

    private const STATE_EMPTY  = 0;
    private const STATE_LOADED = 1;

    private const TITLE_RATIO = 0.20;
    private const ITEM_HEIGHT = 40;
    private const BADGE_SIZE  = 13;
    private const BADGE_GAP   = 2;

    private var _state as Number = STATE_EMPTY;
    private var _favorites as Array<Dictionary> = [];
    private var _selectedIndex as Number = 0;
    private var _topVisibleIndex as Number = 0;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void { }

    function onShow() as Void {
        loadFavorites();
    }

    function loadFavorites() as Void {
        _favorites = mvgFavorites.getFavorites();
        _state = _favorites.size() > 0 ? STATE_LOADED : STATE_EMPTY;
        _selectedIndex = 0;
        _topVisibleIndex = 0;
        WatchUi.requestUpdate();
    }

    // --- Navigation ---

    function scrollDown() as Void {
        if (_favorites.size() == 0) { return; }
        if (_selectedIndex < _favorites.size() - 1) {
            _selectedIndex++;
            ensureVisible(_selectedIndex);
            WatchUi.requestUpdate();
        }
    }

    function scrollUp() as Void {
        if (_favorites.size() == 0) { return; }
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

    // --- Getters ---

    function getSelectedIndex() as Number { return _selectedIndex; }
    function getFavorites() as Array<Dictionary> { return _favorites; }

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

        var titleText = WatchUi.loadResource(Rez.Strings.favorite_title) as String;
        if (_state == STATE_LOADED) {
            titleText = titleText + " (" + _favorites.size().toString() + ")";
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2, titleHeight / 2,
            Graphics.FONT_SMALL,
            titleText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Content ---
        if (_state == STATE_LOADED && _favorites.size() > 0) {
            drawStationList(dc, width, height, titleHeight);
        } else {
            drawEmptyMessage(dc, width, height, titleHeight);
        }
    }

    // --- Draw station list ---

    private function drawStationList(dc as Dc, width as Number, height as Number, titleHeight as Number) as Void {
        var visible = visibleCount();

        for (var i = 0; i < visible; i++) {
            var index = _topVisibleIndex + i;
            if (index >= _favorites.size()) { break; }

            var y = titleHeight + (i * ITEM_HEIGHT);
            var isSelected = (index == _selectedIndex);

            drawStationRow(dc, width, y, _favorites[index] as Dictionary, isSelected);

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
        var nameText = station["name"] as String;
        var badgeCount = types != null ? types.size() : 0;

        // --- Transport badges (right side) ---
        var rightMargin = 5;
        var badgesTotalWidth = badgeCount * (BADGE_SIZE + BADGE_GAP) - BADGE_GAP;
        var badgeStartX = width - rightMargin - 10 - badgesTotalWidth;

        for (var b = 0; b < badgeCount; b++) {
            var bx = badgeStartX + b * (BADGE_SIZE + BADGE_GAP);
            var by = y + (ITEM_HEIGHT / 2) - (BADGE_SIZE / 2);

            var typeStr = types[b] as String;
            var typeColor = getTransportColor(typeStr);

            if (isSelected) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRectangle(bx, by, BADGE_SIZE, BADGE_SIZE);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            } else {
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
        var nameMaxWidth = badgeStartX - 14;
        var maxChars = (nameMaxWidth / 9).toNumber();
        var displayName = nameText;
        if (nameText != null && maxChars > 3 && nameText.length() > maxChars) {
            displayName = nameText.substring(0, maxChars - 1) + "…";
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

    // --- Empty state ---

    private function drawEmptyMessage(dc as Dc, width as Number, height as Number, titleHeight as Number) as Void {
        var msg = WatchUi.loadResource(Rez.Strings.favorite_empty) as String;
        var contentY = titleHeight + (height - titleHeight) / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2, contentY,
            Graphics.FONT_SMALL,
            msg,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // --- Helpers ---

    private function visibleCount() as Number { return 5; }

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
