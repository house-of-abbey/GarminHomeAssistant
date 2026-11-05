// Distributed under MIT Licence.
// See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE

using Toybox.Communications;
using Toybox.Lang;
using Toybox.Test;
using Toybox.WatchUi;

class StatusRecordingApp extends HomeAssistantApp {
    var publications as Lang.Array<Lang.String> = [];

    function initialize() {
        HomeAssistantApp.initialize();
    }

    function publishApiStatus(s as Lang.String) as Void {
        publications.add(s);
    }
}

(:test)
function testUncheckedValue(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual((new StatusRecordingApp()).formatApiStatus("?"), "?");
    return true;
}

(:test)
function testPublisherAcceptsStringValues(logger as Test.Logger) as Lang.Boolean {
    getApp().publishApiStatus("OK");
    getApp().publishApiStatus("ERR");
    getApp().publishApiStatus("?");
    return true;
}

(:test)
function testCompactStatusFormatting(logger as Test.Logger) as Lang.Boolean {
    var app = new StatusRecordingApp();
    Test.assertEqual(app.formatApiStatus(WatchUi.loadResource($.Rez.Strings.Available) as Lang.String), "OK");
    Test.assertEqual(app.formatApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String), "ERR");
    Test.assertEqual(app.formatApiStatus(WatchUi.loadResource($.Rez.Strings.Unconfigured) as Lang.String), "ERR");
    Test.assertEqual(app.formatApiStatus(WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String), "?");
    return true;
}

(:test)
function testStatusSetterPublishes(logger as Test.Logger) as Lang.Boolean {
    var app = new StatusRecordingApp();
    var available = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
    var unavailable = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
    app.setApiStatus(available);
    app.setApiStatus(unavailable);
    Test.assertEqual(app.getApiStatus(), unavailable);
    Test.assertEqual(app.publications.size(), 2);
    Test.assertEqual(app.publications[0], "OK");
    Test.assertEqual(app.publications[1], "ERR");
    return true;
}

(:test)
function testApiSuccessPublishes(logger as Test.Logger) as Lang.Boolean {
    var app = new StatusRecordingApp();
    app.onReturnFetchApiStatus(200, {"message" => "API running."});
    var expected = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
    Test.assertEqual(app.getApiStatus(), expected);
    Test.assertEqual(app.publications.size(), 1);
    Test.assertEqual(app.publications[0], "OK");
    return true;
}

(:test)
function testApiHttpFailuresPublish(logger as Test.Logger) as Lang.Boolean {
    var codes = [401, 403, 404, 500, Communications.NETWORK_REQUEST_TIMED_OUT,
        Communications.BLE_HOST_TIMEOUT, Communications.BLE_CONNECTION_UNAVAILABLE,
        Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, Communications.SECURE_CONNECTION_REQUIRED];
    var expected = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
    for (var i = 0; i < codes.size(); i++) {
        var app = new StatusRecordingApp();
        app.onReturnFetchApiStatus(codes[i], null);
        Test.assertEqual(app.getApiStatus(), expected);
        Test.assertEqual(app.publications.size(), 1);
        Test.assertEqual(app.publications[0], "ERR");
    }
    return true;
}

(:test)
function testMalformedApiSuccessDoesNotPublishAvailable(logger as Test.Logger) as Lang.Boolean {
    var bodies = [null, "not JSON", {}, {"message" => null},
        {"message" => 42}, {"message" => "not running"}];
    var expected = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
    for (var i = 0; i < bodies.size(); i++) {
        var app = new StatusRecordingApp();
        app.onReturnFetchApiStatus(200, bodies[i]);
        Test.assertEqual(app.getApiStatus(), expected);
        Test.assertEqual(app.publications.size(), 1);
        Test.assertEqual(app.publications[0], "ERR");
    }
    return true;
}

(:test)
function testMemoryRetryPreservesObservation(logger as Test.Logger) as Lang.Boolean {
    var app = new StatusRecordingApp();
    var available = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
    app.setApiStatus(available);
    app.onReturnUpdateMenuItems(Communications.NETWORK_RESPONSE_OUT_OF_MEMORY, null);
    Test.assertEqual(app.getApiStatus(), available);
    Test.assertEqual(app.publications.size(), 1);
    Test.assertEqual(app.publications[0], "OK");
    return true;
}

(:test)
function testUnconfiguredApiPublishesWithoutRequest(logger as Test.Logger) as Lang.Boolean {
    var app = new StatusRecordingApp();
    Settings.update();
    Test.assertEqual(Settings.getApiUrl(), "");
    app.fetchApiStatus();
    var expected = WatchUi.loadResource($.Rez.Strings.Unconfigured) as Lang.String;
    Test.assertEqual(app.getApiStatus(), expected);
    Test.assertEqual(app.publications.size(), 1);
    Test.assertEqual(app.publications[0], "ERR");
    return true;
}

(:test)
function testSettingsResetPublishedObservation(logger as Test.Logger) as Lang.Boolean {
    var app = new StatusRecordingApp();
    app.setApiStatus(WatchUi.loadResource($.Rez.Strings.Available) as Lang.String);
    app.onSettingsChanged();
    Test.assertEqual(app.publications.size(), 2);
    Test.assertEqual(app.publications[1], "?");
    return true;
}

(:test)
function testPublishKnownObservation(logger as Test.Logger) as Lang.Boolean {
    getApp().setApiStatus(WatchUi.loadResource($.Rez.Strings.Available) as Lang.String);
    return true;
}
