import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

module mvgFavorites {

    const FAVORITES_KEY = "favorites";

    // --- Retrieve all favorites ---

    function getFavorites() as Array<Dictionary> {
        var raw = Application.Storage.getValue(FAVORITES_KEY);
        if (raw == null) {
            return [];
        }
        var favs = raw as Array<Dictionary>;
        return favs != null ? favs : [];
    }

    // --- Add a station to favorites ---
    // Returns true if newly added, false if already existed

    function addFavorite(station as Dictionary) as Boolean {
        var favs = getFavorites();
        var globalId = station["globalId"] as String;

        // Deduplicate by globalId
        for (var i = 0; i < favs.size(); i++) {
            var existingId = favs[i]["globalId"] as String;
            if (existingId != null && globalId != null && existingId.equals(globalId)) {
                System.println("Favorites: already exists — " + station["name"]);
                return false;
            }
        }

        // Store a lightweight snapshot of the station
        var fav = {
            "name"           => station["name"],
            "globalId"        => globalId,
            "transportTypes"  => station["transportTypes"],
        };

        favs.add(fav);
        Application.Storage.setValue(FAVORITES_KEY, favs);
        System.println("Favorites: added " + station["name"]);
        return true;
    }

    // --- Remove a station from favorites ---
    // Returns true if removed, false if it wasn't there

    function removeFavorite(station as Dictionary) as Boolean {
        var favs = getFavorites();
        var globalId = station["globalId"] as String;

        for (var i = 0; i < favs.size(); i++) {
            var existingId = favs[i]["globalId"] as String;
            if (existingId != null && globalId != null && existingId.equals(globalId)) {
                favs.remove(favs[i]);
                Application.Storage.setValue(FAVORITES_KEY, favs);
                System.println("Favorites: removed " + station["name"]);
                return true;
            }
        }
        return false;
    }

    // --- Check whether a station is already favorited ---

    function isFavorite(station as Dictionary) as Boolean {
        var favs = getFavorites();
        if (station["globalId"] == null) {
            return false;
        }
        var globalId = station["globalId"] as String;

        for (var i = 0; i < favs.size(); i++) {
            var existingId = favs[i]["globalId"] as String;
            if (existingId != null && existingId.equals(globalId)) {
                return true;
            }
        }
        return false;
    }
}
