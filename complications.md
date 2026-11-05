[Home](README.md) | [Switches](examples/Switches.md) | [Actions](examples/Actions.md) | [Templates](examples/Templates.md) | [Numeric](examples/Numeric.md) | [Select](examples/Select.md) | [Glance](examples/Glance.md) | [Background Service](BackgroundService.md) | [Wi-Fi](Wi-Fi.md) | [HTTP Headers](HTTP_Headers.md) | [Trouble Shooting](TroubleShooting.md) | [Version History](HISTORY.md)

# Complications

## For Watch Face Developers

The watch face needs the `ComplicationSubscriber` permission and a device supporting the [Complications API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html) (introduced in Connect IQ API 4.2). Enumerate the complications available to your watch face using `Complications.getComplications()` and let the user select the HomeAssistant entry. Connect IQ complications have type `COMPLICATION_TYPE_INVALID`, unlike the built-in system complication types.

The complication provides the long label `HomeAssistant`, the short label `HA`, an icon, and a string value. Existing application/glance API-status observations publish one of three language-independent values: `OK` (successful), `ERR` (connection, API, or configuration failure), or `?` (not checked). Initially the value is `?`, and settings changes reset it to `?`. There is no timestamp or detailed error text in the complication value; localized status messages within the application are unchanged. `ERR` does not necessarily mean the Home Assistant server itself is offline.

The value is the last observed connection status, not a live health check or an entity state. It is not refreshed after the app/glance closes, and no new networking, timers, or background events are introduced. A consuming watch face must not present `OK` as a guarantee of current availability; the compact value does not indicate its age. It can obtain the publisher's icon using `Complication.getIcon()` even before the first status check.

For example, the following function finds a matching entry when there is only one HomeAssistant installation:

```monkeyc
import Toybox.Complications;

function findHomeAssistantComplication() as Complications.Id? {
    var iterator = Complications.getComplications();
    var complication = iterator.next();
    while (complication != null) {
        var label = complication.longLabel;
        if (complication.getType() == Complications.COMPLICATION_TYPE_INVALID &&
            label != null && label.equals("HomeAssistant")) {
            return complication.complicationId;
        }
        complication = iterator.next();
    }
    return null;
}
```

In the watch face's [`WatchFaceDelegate.onPress()`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFaceDelegate.html#onPress-instance_function) handler, call [`Complications.exitTo()`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html#exitTo-instance_function) with the selected non-null `Complications.Id`. This opens the ordinary application entry point; no special launch parameters or publisher callbacks are required.

Use the actual returned Id, not a list position or a label alone, for a saved selection. [`Application.Storage`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html#setValue-instance_function) supports storing `Complications.Id` since API 4.2. Labels are not unique when, for example, a test build is installed alongside the store application. The resource index is `0` and must remain stable in future releases, but is not a built-in `Complications.Type` that can be passed to `new Complications.Id()`.

Handle a missing or uninstalled application without launching an unrelated target. A launch can fail with `Lang.InvalidValueException` if the Id does not belong to a valid application; account for this when implementing the interaction. Subscribing to value updates is not needed just to launch the app; watch faces displaying the status can use `registerComplicationChangeCallback()` and `subscribeToUpdates()`. Firmware controls confirmation dialogs, wake-up handling, and return navigation, so these should be checked on the target watch. `System.exitTo()` is not an alternative for watch faces; that API is restricted to watch-apps and widgets.

## Testing Status Display and Launch with Fallout

The compact status value and touch-and-hold application launch have been tested successfully on a fenix 8 using [Fallout by frinkr](https://apps.garmin.com/apps/b4d5c6d9-e2d4-4143-8fec-d8cc89d7db6f). Fallout lists long-press widget launching as a PRO feature, also available during its full-feature trial.

1. Install a GarminHomeAssistant build containing the status complication and configure it normally. Install the latest Fallout watch face on a device supported by that watch face.
2. In Fallout's settings in the Connect IQ phone app, assign **Custom Complication** to a visible data field.
3. Also enable **Allow touch** in Fallout's settings. This is required for the launch interaction.
4. On the watch, open Fallout's **Customize** menu, choose **Custom Complication**, select **HomeAssistant**, and apply the customization.
5. Open GarminHomeAssistant normally, wait for the existing API check to complete, then return to the watch face. The field should show `OK` after a successful check, or `ERR` after a failed check. Before the first check, the value is `?`.
6. Touch and hold the complication data field to launch GarminHomeAssistant.

The selected publisher must be the same installation that you open, especially if a test build is installed alongside the store application. The last status can remain visible after the app closes; it is not continuously monitored.

In the fenix 8 test, Fallout showed a branching symbol instead of the Home Assistant icon. The publisher's icon displayed correctly in a separate custom watch face built with [Watchface Builder](https://garmin.watchfacebuilder.com/). Watchface Builder does not expose a supported touch-and-hold handler for launching the app, so that test only confirmed icon rendering, not application launch. Each watch face controls its own rendering and interactions; the cause of Fallout's different icon has not been confirmed. These hardware tests were on the fenix 8, not a Venu 2. See [frinkr's complication setup guide](https://ko-fi.com/post/Complications-S6S21PPWWW) for its current instructions.

## Compatibility and Testing

The complication resources are included only in the device-specific `resourcePath` entries marked with `resources-complication` in `monkey.jungle`. The application's minimum API level remains 3.1; older watches and devices without complication support keep their existing launch methods. When adding a device, check Garmin's supported-device list and its SDK device metadata before adding the complication resource directory.

For a release, build both complication-capable and legacy targets and export a mixed-device IQ package. On real hardware, verify discovery in a consuming watch face, touch-and-hold launch, the existing menu and settings, return to the watch face, and removal/reinstallation of the application. Check the initial `?`, exact `OK`/`ERR` values for successful/failed API responses, `ERR` for missing configuration or connectivity, settings-change reset, and retention of the last status after closing the app. No value should contain a timestamp or localized error text. A local out-of-memory retry must preserve the previous status. Also check that an initial touch on an always-on display does not unexpectedly trigger the shortcut. Simulator builds do not verify these firmware interactions.

The status-formatting and callback tests use an unconfigured simulator instance (no Home Assistant requests). Build with `monkeyc -d fenix847mm -f "monkey.jungle;monkey-test.jungle" -y /path/to/developer_key.der --unit-test -o bin/complication-tests.prg`, then run `monkeydo bin/complication-tests.prg fenix847mm -t` with the simulator open. The test sources are not included in normal builds.

## Credits

With thanks to [@therau5ch](https://github.com/therau5ch) for contributing this solution.
