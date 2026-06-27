import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class mvgView extends WatchUi.View {

    private var _selectedIndex as Number = 0;

    private const MENU_ITEMS = [
        WatchUi.loadResource(Rez.Strings.menu_favorite) as String,
        WatchUi.loadResource(Rez.Strings.menu_nearby) as String,
    ];

    private const ITEM_COUNT = 2;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // Layout is handled in onUpdate with custom drawing
    }

    function onShow() as Void {
        // Reset selection when the view is shown
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
            WatchUi.loadResource(Rez.Strings.menu_main) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Menu items ---
        var itemStartY = titleHeight;
        var itemHeight = (height - titleHeight) / ITEM_COUNT;

        for (var i = 0; i < ITEM_COUNT; i++) {
            var y = itemStartY + (i * itemHeight);

            if (i == _selectedIndex) {
                // Highlighted item
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.fillRectangle(0, y, width, itemHeight);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                // Normal item
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRectangle(0, y, width, itemHeight);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }

            // Draw a subtle separator line between items
            if (i > 0) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.drawLine(10, y, width - 10, y);
            }

            // Draw the icon placeholder (left-aligned circle)
            var iconX = width * 0.18;
            var iconY = y + (itemHeight / 2);
            var iconRadius = 10;

            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(iconX, iconY, iconRadius);

            // Draw an icon glyph inside the circle
            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            }
            // Simple icon: dot or arrow depending on item
            if (i == 0) {
                // Star shape for Favorite (simplified as a filled square)
                dc.fillPolygon([
                    [iconX, iconY - 5],
                    [iconX + 4, iconY - 2],
                    [iconX + 5, iconY + 2],
                    [iconX + 2, iconY + 4],
                    [iconX, iconY + 6],
                    [iconX - 2, iconY + 4],
                    [iconX - 5, iconY + 2],
                    [iconX - 4, iconY - 2],
                ]);
            } else {
                // Crosshair / location dot for Nearby
                dc.fillCircle(iconX, iconY, 4);
            }

            // Draw the label text
            var textX = iconX + iconRadius + 15;
            var textY = y + (itemHeight / 2);

            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(
                textX,
                textY,
                Graphics.FONT_MEDIUM,
                MENU_ITEMS[i],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

            // Draw a right-pointing chevron
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
}
