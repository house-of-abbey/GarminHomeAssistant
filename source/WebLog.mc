//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
// tested on a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistant
//
// J D Abbey & P A Abbey, 28 December 2022
//
//-----------------------------------------------------------------------------------

using Toybox.Communications;
using Toybox.Lang;
using Toybox.System;

//! WebLog provides a logging and hence debugging aid for when the application is
//! deployed to the watch. This is only used for development and use of it must not
//! persist into a deployed version. It uses a string buffer to group log entries into
//! larger submissions in order to prevent overflow of the Bluetooth stack.
//!
//! Usage:
//! <pre>
//!   wl = new WebLog();
//!   wl.clear();
//!   wl.println("Debug Message");
//!   wl.flush();
//! </pre>
//!
//! File: https://domain.name/path/log.php
//!
//! <pre>
//! &lt;?php
//!   $myfile = fopen("log", "a");
//!   $queries = array();
//!   parse_str($_SERVER['QUERY_STRING'], $queries);
//!   fwrite($myfile, $queries['log']);
//!   print "Success";
//! ?&gt;
//! </pre>
//!
//! Logs published to https://domain.name/path/log.
//!
//! File: https://domain.name/path/log_clear.php
//!
//! <pre>
//! &lt;?php
//!   $myfile = fopen("log", "w");
//!   fwrite($myfile, "");
//!   print "Success";
//! ?&gt;
//! </pre>
//
(:glance, :background)
class WebLog {
    private var callsBuffer =  4 as Lang.Number;
    private var numCalls    =  0 as Lang.Number;
    private var buffer      = "" as Lang.String;

    //! Set the number of calls to print() before sending the buffer to the online
    //! logger.
    //!
    //! @param l The number of log calls to buffer before writing to the online service.
    //
    function setCallsBuffer(l as Lang.Number) {
        callsBuffer = l;
    }

    //! Get the number of calls to print() before sending the buffer to the online
    //! logger.
    //!
    //! @return The number of log calls to buffer before writing to the online service.
    //
    function getCallsBuffer() as Lang.Number {
        return callsBuffer;
    }

    //! Create a debug log over the Internet to keep track of the watch's runtime
    //! execution.
    //!
    //! @param str The string to log.
    //
    function print(str as Lang.String) {
        var myTime = System.getClockTime();
        buffer += myTime.hour.format("%02d") + ":" + myTime.min.format("%02d") + ":" + myTime.sec.format("%02d") + " " + str;
        numCalls++;
        // System.println("WebLog print() str      = " + str);
        if (numCalls >= callsBuffer) {
            doPrint();
        }
    }

    //! Create a debug log over the Internet to keep track of the watch's runtime
    //! execution. Add a new line character to the end.
    //!
    //! @param str The string to log.
    //
    function println(str as Lang.String) {
        print(str + "\n");
    }

    //! Flush the current buffer to the online logger even if it has not reach the
    //! submission level set by 'callsBuffer'.
    //
    function flush() {
        // System.println("WebLog flush()");
        if (numCalls > 0) {
            doPrint();
        }
    }

    //! Perform the submission to the online logger.
    //
    function doPrint() {
        // System.println("WebLog doPrint()");
        // System.println(buffer);
        Communications.makeWebRequest(
            ClientId.webLogUrl,
            { "log" => buffer },
            {
                :method  => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
            },
            method(:onLog)
        );
        numCalls = 0;
        buffer   = "";
    }

    //! Clear the debug log over the Internet to start a new track of the watch's runtime
    //! execution.
    //
    function clear() {
        // System.println("WebLog clear()");
        Communications.makeWebRequest(
            ClientId.webLogClearUrl,
            {},
            {
                :method  => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
            },
            method(:onClear)
        );
        numCalls = 0;
        buffer   = "";
    }

    //! Callback function to print the outcome of a doPrint() method. Typically used for debugging this class.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //
    function onLog(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        // if (responseCode != 200) {
        //     System.println("WebLog onLog() Failed");
        //     System.println("WebLog onLog() Response Code: " + responseCode);
        //     System.println("WebLog onLog() Response Data: " + data);
        // }
    }

    //! Callback function to print the outcome of a clear() method. Typically used for debugging this class.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //
    function onClear(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        // if (responseCode != 200) {
        //     System.println("WebLog onClear() Failed");
        //     System.println("WebLog onClear() Response Code: " + responseCode);
        //     System.println("WebLog onClear() Response Data: " + data);
        // }
    }
}
