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
// P A Abbey & J D Abbey & Someone0nEarth, 31 October 2023
//
//
// Description:
//
// Load the strings centrally once rather than initialising locally within separate
// classes. This is to solve a problem with out of memory errors in some devices,
// e.g. Vivoactive 3.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;

class RezStrings {

    (:glance)
    static var strAppName           as Lang.String     or Null;
    static var strMenuItemTap       as Lang.String     or Null;
    static var strMenuItemMenu      as Lang.String     or Null;
    static var strConfirm           as Lang.String     or Null;
    (:glance)
    static var strNoPhone           as Lang.String     or Null;
    static var strNoInternet        as Lang.String     or Null;
    static var strNoResponse        as Lang.String     or Null;
    (:glance)
    static var strNoApiKey          as Lang.String     or Null;
    (:glance)
    static var strNoApiUrl          as Lang.String     or Null;
    (:glance)
    static var strNoConfigUrl       as Lang.String     or Null;
    static var strApiFlood          as Lang.String     or Null;
    static var strApiUrlNotFound    as Lang.String     or Null;
    static var strConfigUrlNotFound as Lang.String     or Null;
    static var strNoJson            as Lang.String     or Null;
    static var strUnhandledHttpErr  as Lang.String     or Null;
    static var strTrailingSlashErr  as Lang.String     or Null;
    (:glance)
    static var strAvailable         as Lang.String     or Null;
    (:glance)
    static var strChecking          as Lang.String     or Null;
    (:glance)
    static var strUnavailable       as Lang.String     or Null;
    (:glance)
    static var strUnconfigured      as Lang.String     or Null;
    (:glance)
    static var strGlanceMenu        as Lang.String     or Null;
    static var strLabelToggle       as Lang.Dictionary or Null;

    // Can't initialise a constant directly, have to be initialised via a function
    // for 'WatchUi.loadResource' to be available.
    (:glance)
    static function update_glance() {
        strAppName      = WatchUi.loadResource($.Rez.Strings.AppName);
        strNoPhone      = WatchUi.loadResource($.Rez.Strings.NoPhone);
        strNoApiKey     = WatchUi.loadResource($.Rez.Strings.NoAPIKey);
        strNoApiUrl     = WatchUi.loadResource($.Rez.Strings.NoApiUrl);
        strNoConfigUrl  = WatchUi.loadResource($.Rez.Strings.NoConfigUrl);
        strAvailable    = WatchUi.loadResource($.Rez.Strings.Available);
        strChecking     = WatchUi.loadResource($.Rez.Strings.Checking);
        strUnavailable  = WatchUi.loadResource($.Rez.Strings.Unavailable);
        strUnconfigured = WatchUi.loadResource($.Rez.Strings.Unconfigured);
        strGlanceMenu   = WatchUi.loadResource($.Rez.Strings.GlanceMenu);
    }

    // Can't initialise a constant directly, have to be initialised via a function
    // for 'WatchUi.loadResource' to be available.
    static function update() {
        strAppName           = WatchUi.loadResource($.Rez.Strings.AppName);
        strMenuItemTap       = WatchUi.loadResource($.Rez.Strings.MenuItemTap);
        strMenuItemMenu      = WatchUi.loadResource($.Rez.Strings.MenuItemMenu);
        strConfirm           = WatchUi.loadResource($.Rez.Strings.Confirm);
        strNoPhone           = WatchUi.loadResource($.Rez.Strings.NoPhone);
        strNoInternet        = WatchUi.loadResource($.Rez.Strings.NoInternet);
        strNoResponse        = WatchUi.loadResource($.Rez.Strings.NoResponse);
        strNoApiKey          = WatchUi.loadResource($.Rez.Strings.NoAPIKey);
        strNoApiUrl          = WatchUi.loadResource($.Rez.Strings.NoApiUrl);
        strNoConfigUrl       = WatchUi.loadResource($.Rez.Strings.NoConfigUrl);
        strApiFlood          = WatchUi.loadResource($.Rez.Strings.ApiFlood);
        strApiUrlNotFound    = WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound);
        strConfigUrlNotFound = WatchUi.loadResource($.Rez.Strings.ConfigUrlNotFound);
        strNoJson            = WatchUi.loadResource($.Rez.Strings.NoJson);
        strUnhandledHttpErr  = WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr);
        strTrailingSlashErr  = WatchUi.loadResource($.Rez.Strings.TrailingSlashErr);
        strAvailable         = WatchUi.loadResource($.Rez.Strings.Available);
        strChecking          = WatchUi.loadResource($.Rez.Strings.Checking);
        strUnavailable       = WatchUi.loadResource($.Rez.Strings.Unavailable);
        strUnconfigured      = WatchUi.loadResource($.Rez.Strings.Unconfigured);
        strGlanceMenu        = WatchUi.loadResource($.Rez.Strings.GlanceMenu);
        strLabelToggle       = {
            :enabled  => WatchUi.loadResource($.Rez.Strings.MenuItemOn)  as Lang.String,
            :disabled => WatchUi.loadResource($.Rez.Strings.MenuItemOff) as Lang.String
        };
    }
}
