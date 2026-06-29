# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development

This is a **Garmin Connect IQ** widget written in **Monkey C**. Development uses the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (5.2+) and the **Monkey C VS Code extension**, which provides build, run, and configuration commands.

- **Build/Run**: Use the VS Code command palette (`Monkey C: Build for Device`, `Monkey C: Run`, etc.). The project self-describes via `manifest.xml` and `monkey.jungle`.
- **Build output**: `bin/mvg.prg` (compiled widget) and `bin/mvg.prg.debug.xml` (debug info). Intermediate artifacts live in `bin/gen/`, `bin/mir/`, `bin/internal-mir/`.
- **Entry point**: `mvgApp` class in `source/mvgApp.mc`.
- **App type**: Widget (`type="widget"` in manifest).
- **API level**: 5.2.0 minimum.
- **Target device**: fenix7 (configured in manifest). Adjust `iq:products` in `manifest.xml` to target other devices.
- **Permissions**: `Positioning` (GPS), `Communications` (Bluetooth/HTTP), `PersistedContent` (storage).
- **Language**: English only.

## Architecture

The app uses Garmin's MVC-like pattern: each screen is a **View** (custom-drawn, no XML layouts) paired with a **BehaviorDelegate** for button/press input. Navigation is via `WatchUi.pushView`/`WatchUi.popView`.

### View stack (navigation flow)

```
Widget loop:  mvgGlanceView (shows next departure from last-viewed station)

Open widget:  mvgView (main menu)
              ├── Favorites → mvgFavoriteView → select station → mvgStationMenuView
              │                   ├── Departures → mvgDepartureView (live departure board)
              │                   └── Add/Remove Favorite
              └── Nearby → mvgNearbyGpsView (choose "Refresh GPS" or "Use last known")
                             → mvgNearbyView (station list from GPS)
                             → mvgStationMenuView → mvgDepartureView
```

### Key patterns

- **Views are custom-drawn**: Every View overrides `onUpdate(dc)` and draws manually using `dc.drawText`, `dc.fillRectangle`, etc. No layout XML is used (despite `resources/layouts/layout.xml` existing as a stub). Title bars are consistently 20% of screen height (`TITLE_RATIO = 0.20`).
- **Delegate pattern**: Most Views have a paired Delegate that holds a reference back to the View for scroll/selection control. Buttons (`onSelect`, `onNextPage`, `onPreviousPage`, `onBack`) delegate to View methods like `scrollDown()`/`scrollUp()`.
- **Internal state machines**: List views use `STATE_LOADING` / `STATE_ERROR` / `STATE_LOADED` (or `STATE_EMPTY`) to drive rendering.
- **Scrolling**: List views maintain `_selectedIndex` and `_topVisibleIndex` with `ensureVisible()` logic for viewport tracking.

### API integration

Two MVG endpoints are used (base: `https://www.mvg.de/api/bgw-pt/v3/`):

| Endpoint | File | Purpose |
|---|---|---|
| `GET /stations/nearby?latitude=...&longitude=...` | `mvgNearbyView.mc` | Find nearby stations by GPS |
| `GET /departures?globalId=...&limit=...&offsetInMinutes=0` | `mvgDepartureView.mc`, `mvgGlanceView.mc` | Get real-time departures for a station |

Both use `Communications.makeWebRequest` with JSON response type. Global IDs have colons encoded as `%3A` before being passed as query params.

### Persistence (Application.Storage)

| Module | Storage Key | Data |
|---|---|---|
| `mvgFavorites` | `"favorites"` | Array of `{name, globalId, transportTypes}` |
| `mvgLastStation` | `"lastStation"` | Single `{name, globalId, transportTypes}` |

`mvgLastStation` is updated every time a user taps "Departures" from the station menu, enabling the glance view to show relevant data. Glance view loads the next departure on `onShow()`.

### Transport type color coding

U-Bahn = Blue, Tram = Red, Bus = Dark Green, S-Bahn = Green, other = Light Gray. Defined in both `mvgDepartureView.mc` and `mvgGlanceView.mc` (duplicated helper — extracted here for visibility, but note the duplication).

### GPS handling (`mvgNearbyView.mc`)

Two modes: **event-based** (`Position.enableLocationEvents` with `LOCATION_ONE_SHOT` → callback `onPosition`) for a fresh fix, or **sync** (`Position.getInfo()`) for last-known position. Falls back to last-known if event-based quality is below `QUALITY_USABLE`.

### File map

| File | Role |
|---|---|
| `mvgApp.mc` | Entry point, returns glance + initial view |
| `mvgView.mc` | Main menu (Favorites / Nearby) |
| `mvgDelegate.mc` | Main menu input handling + navigation dispatch |
| `mvgGlanceView.mc` | Widget-loop preview showing next departure |
| `mvgNearbyView.mc` | GPS-based nearby station search + list |
| `mvgNearbyDelegate.mc` | Station selection from nearby list |
| `mvgNearbyGpsView.mc` | GPS mode chooser (refresh vs last known) |
| `mvgNearbyGpsDelegate.mc` | Input handling for GPS mode chooser |
| `mvgFavoriteView.mc` | Saved favorites list |
| `mvgFavoriteDelegate.mc` | Favorite selection + refresh callback after removal |
| `mvgFavorites.mc` | Module: favorites CRUD via Application.Storage |
| `mvgLastStation.mc` | Module: last-viewed station persistence |
| `mvgStationMenuView.mc` | Shared station action menu (departures / toggle favorite) |
| `mvgStationMenuDelegate.mc` | Station menu actions + optional remove callback |
| `mvgDepartureView.mc` | Live departure board (loading, delay badges, cancellation display) |
| `mvgDepartureDelegate.mc` | Departure view input (scroll, back; select is TODO) |
| `mvgMenuDelegate.mc` | Unused — wired to a menu.xml that may not be active |
