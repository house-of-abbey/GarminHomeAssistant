[Home](README.md) | [Switches](examples/Switches.md) | [Actions](examples/Actions.md) | [Templates](examples/Templates.md) | [Numeric](examples/Numeric.md) | [Select](examples/Select.md) | [Glance](examples/Glance.md) | [Background Service](BackgroundService.md) | [Wi-Fi](Wi-Fi.md) | [HTTP Headers](HTTP_Headers.md) | [Trouble Shooting](TroubleShooting.md) | [Version History](HISTORY.md)

# Complications

## For Watch Face Developers

The watch face needs the `ComplicationSubscriber` permission and a device supporting the [Complications API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html) (introduced in Connect IQ API 4.2). Enumerate the complications available to your watch face using `Complications.getComplications()` and let the user select the HomeAssistant entry. Connect IQ complications have type `COMPLICATION_TYPE_INVALID`, unlike the built-in system complication types.

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

Handle a missing or uninstalled application without launching an unrelated target. A launch can fail with `Lang.InvalidValueException` if the Id does not belong to a valid application; account for this when implementing the interaction. Subscribing to value updates is not needed for this static shortcut. Firmware controls confirmation dialogs, wake-up handling, and return navigation, so these should be checked on the target watch. `System.exitTo()` is not an alternative for watch faces; that API is restricted to watch-apps and widgets.

## Compatibility and Testing

The complication resources are included only in the device-specific `resourcePath` entries marked with `resources-complication` in `monkey.jungle`. The application's minimum API level remains 3.1; older watches and devices without complication support keep their existing launch methods. When adding a device, check Garmin's supported-device list and its SDK device metadata before adding the complication resource directory.

For a release, build both complication-capable and legacy targets and export a mixed-device IQ package. On real hardware, verify discovery in a consuming watch face, touch-and-hold launch, the existing menu and settings, return to the watch face, and removal/reinstallation of the application. Also check that an initial touch on an always-on display does not unexpectedly trigger the shortcut. Simulator builds do not verify these firmware interactions.
