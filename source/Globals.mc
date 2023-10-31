using Toybox.Lang;

class Globals {
    // Enable printing of messages to the debug console (don't make this a Property
    // as the messages can't be read from a watch!)
    static const debug          = false;
    static const updateInterval = 5; // seconds
//    static hidden const apiUrl  = "https://homeassistant.local/api";
    static hidden const apiUrl  = "https://home.abbey1.org.uk/api";

    static function getApiUrl() {
        return apiUrl;
    }

}
