//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistantWidget/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistantWidget is a Garmin IQ widget written in Monkey C. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistantWidget.
//
// P A Abbey & J D Abbey & Someone0nEarth, 31 October 2023
//
//
// Description:
//
// Home Assistant centralised constants.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;

class Globals {
    static const scAlertTimeout = 2000; // ms
    static const scTapTimeout   = 1000; // ms
    // Time to let the existing HTTP responses get serviced after a
    // Communications.NETWORK_RESPONSE_OUT_OF_MEMORY response code.
    static const scApiBackoff   = 1000; // ms
    // Needs to be long enough to enable a "double ESC" to quit the application from
    // an ErrorView.
    static const scApiResume    = 200;  // ms
    // Warn the user after fetching the menu if their watch is low on memory before the device crashes.
    static const scLowMem       = 0.90; // percent as a fraction.
}
