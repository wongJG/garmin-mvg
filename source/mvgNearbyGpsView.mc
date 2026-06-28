import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class mvgNearbyGpsView extends WatchUi.View {

    private var _selectedIndex as Number = 0;
    private var _nearbyView as mvgNearbyView;

    private const ITEM_COUNT = 2;

    function initialize(nearbyView as mvgNearbyView) {
        View.initialize();
        _nearbyView = nearbyView;
    }

    function onLayout(dc as Dc) as Void {
        // Layout is handled in onUpdate with custom drawing
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var width = dc.getWidth();
        var height = dc.getHeight();

        // --- Background ---
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // --- Title bar ---
        var titleHeight = height * 0.20;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, width, titleHeight);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            titleHeight / 2,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.nearby_title) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Menu items ---
        var itemStartY = titleHeight;
        var itemHeight = (height - titleHeight) / ITEM_COUNT;

        var labels = [
            WatchUi.loadResource(Rez.Strings.nearby_gps_refresh) as String,
            WatchUi.loadResource(Rez.Strings.nearby_gps_last) as String,
        ];

        for (var i = 0; i < ITEM_COUNT; i++) {
            var y = itemStartY + (i * itemHeight);

            // --- Row background ---
            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            } else {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            }
            dc.fillRectangle(0, y, width, itemHeight);

            // --- Separator line between items ---
            if (i > 0) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.drawLine(10, y, width - 10, y);
            }

            // --- Icon ---
            var iconX = width * 0.18;
            var iconY = y + (itemHeight / 2);
            var fgColor = (i == _selectedIndex) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;

            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);

            if (i == 0) {
                // Refresh GPS: crosshair (circle outline + center dot)
                var radius = 9;
                // Draw circle outline by filling then erasing center
                dc.fillCircle(iconX, iconY, radius);
                var bgColor = (i == _selectedIndex) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
                dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(iconX, iconY, radius - 2);
                dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(iconX, iconY, 3);
            } else {
                // Use last known: filled circle (cached location)
                dc.fillCircle(iconX, iconY, 9);
                var bgColor = (i == _selectedIndex) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
                dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(iconX, iconY, 3);
                dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
            }

            // --- Label text ---
            var textX = iconX + 25;
            var textY = y + (itemHeight / 2);

            dc.drawText(
                textX,
                textY,
                Graphics.FONT_SMALL,
                labels[i],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

            // --- Right chevron ---
            var chevronX = width - 20;
            var chevronY = y + (itemHeight / 2);
            var chevronSize = 8;

            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawLine(chevronX, chevronY - chevronSize, chevronX + chevronSize, chevronY);
            dc.drawLine(chevronX, chevronY + chevronSize, chevronX + chevronSize, chevronY);
        }
    }

    function setSelectedIndex(index as Number) as Void {
        _selectedIndex = index;
        WatchUi.requestUpdate();
    }

    function getSelectedIndex() as Number {
        return _selectedIndex;
    }

    function getNearbyView() as mvgNearbyView {
        return _nearbyView;
    }
}
