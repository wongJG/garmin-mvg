import Toybox.Application;
import Toybox.Lang;

module mvgLastStation {

    const LAST_STATION_KEY = "lastStation";

    // --- Save the last viewed station ---

    function saveLastStation(station as Dictionary) as Void {
        var entry = {
            "name"           => station["name"],
            "globalId"        => station["globalId"],
            "transportTypes"  => station["transportTypes"],
        };
        Application.Storage.setValue(LAST_STATION_KEY, entry);
    }

    // --- Retrieve the last viewed station (null if none) ---

    function getLastStation() as Dictionary? {
        var raw = Application.Storage.getValue(LAST_STATION_KEY);
        if (raw == null) {
            return null;
        }
        return raw as Dictionary;
    }
}
