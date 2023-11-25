//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
// tested on a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistant.
//
// P A Abbey & J D Abbey, SomeoneOnEarth, 23 November 2023
//
//
// Description:
//
// Home Assistant settings.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Application.Properties;

class Settings {

    private static var instance;

    private var strApiKey                 as Lang.String;
    private var strApiUrl                 as Lang.String;
    private var strConfigUrl              as Lang.String;
    private var bRepresentTypesWithLabels as Lang.Boolean;
    private var bMenuItemAlignmentRight   as Lang.Boolean;

    private function initialize() {
        strApiKey                 = Properties.getValue("api_key");
        strApiUrl                 = Properties.getValue("api_url");
        strConfigUrl              = Properties.getValue("config_url");
        bRepresentTypesWithLabels = Properties.getValue("types_representation");
        bMenuItemAlignmentRight   = Properties.getValue("menu_alignment");
    }

    static function get() as Settings {
        if (instance == null) {
            instance = new Settings();
        }
        return instance;
    }

    function apiKey() as Lang.String {
        return strApiKey;
    }

    function apiUrl() as Lang.String {
        return strApiUrl;
    }

    function configUrl() as Lang.String {
        return strConfigUrl;
    }

    function menuItemAlignmentRight() as Lang.Boolean {
        return bMenuItemAlignmentRight;
    }

    function showTypeLabels() as Lang.Boolean {
        return bRepresentTypesWithLabels;
    }
}
