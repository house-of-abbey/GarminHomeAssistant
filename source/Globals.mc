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
// P A Abbey & J D Abbey & Someone0nEarth & moesterheld, 31 October 2023
//
//
// Description:
//
// Home Assistant centralised constants.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;

(:glance)
class Globals {
    static const scAlertTimeout          = 2000; // ms
    static const scTapTimeout            = 1000; // ms
    // Time to let the existing HTTP responses get serviced after a
    // Communications.NETWORK_RESPONSE_OUT_OF_MEMORY response code.
    static const scApiBackoff            = 1000; // ms
    // Needs to be long enough to enable a "double ESC" to quit the application from
    // an ErrorView.
    static const scApiResume             = 200;  // ms
    // Warn the user after fetching the menu if their watch is low on memory before the device crashes.
    static const scLowMem                = 0.90; // percent as a fraction.

    // Constants for PIN confirmation dialog
    static const scPinMaxFailures        = 5;  // Maximum number of failed PIN confirmation attemps allwed in ...
    static const scPinMaxFailureMinutes  = 2;  // ... this number of minutes before PIN confirmation is locked for ...
    static const scPinLockTimeMinutes    = 10; // ... this number of minutes
}
