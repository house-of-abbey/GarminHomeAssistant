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
// P A Abbey & J D Abbey, 24 August 2024
//
//
// Description:
//
// Menu button that renders a Home Assistant Template.
//
// Reference:
//  * https://developers.home-assistant.io/docs/api/rest/
//  * https://www.home-assistant.io/docs/configuration/templating
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

class TemplateMenuItem extends WatchUi.IconMenuItem {
    private var mTemplate as Lang.String;
    private var mCallback as Method() as Void;

    function initialize(
        label    as Lang.String or Lang.Symbol,
        template as Lang.String,
        // Do not use Lang.Method as it does not compile!
        callback as Method() as Void,
        icon     as Graphics.BitmapType or WatchUi.Drawable,
        options  as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null
    ) {
        WatchUi.IconMenuItem.initialize(
            label,
            null,
            null,
            icon,
            options
        );

        mTemplate = template;
        mCallback = callback;
    }

    // Callback function after completing the GET request to fetch the status.
    // Terminate updating the toggle menu items via the chain of calls for a permanent network
    // error. The ErrorView cancellation will resume the call chain.
    //
    function onReturnGetState(responseCode as Lang.Number, data as Null or Lang.Dictionary) as Void {
        // System.println("TemplateMenuItem onReturnGetState() Response Code: " + responseCode);
        // System.println("TemplateMenuItem onReturnGetState() Response Data: " + data);

        var status = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("TemplateMenuItem onReturnGetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("TemplateMenuItem onReturnGetState() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("TemplateMenuItem onReturnGetState() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("TemplateMenuItem onReturnGetState() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                // System.println("TemplateMenuItem onReturnGetState() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                var myTimer = new Timer.Timer();
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                myTimer.start(getApp().method(:updateNextMenuItem), Globals.scApiBackoff, false);
                // Revert status
                status = getApp().getApiStatus();
                break;

            case 404:
                // System.println("TemplateMenuItem onReturnGetState() Response Code: 404, page not found. Check API URL setting.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound) as Lang.String);
                break;

            case 400:
                // System.println("TemplateMenuItem onReturnGetState() Response Code: 400, bad request. Template error.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
                break;

            case 200:
                status = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
                var label = data.get("request");
                if (label == null) {
                    setSubLabel($.Rez.Strings.Empty);
                } else if(label instanceof Lang.String) {
                    setSubLabel(label);
                } else if(label instanceof Lang.Dictionary) {
                    // System.println("TemplateMenuItem onReturnGetState() label = " + label);
                    if (label.get("error") != null) {
                        setSubLabel($.Rez.Strings.TemplateError);
                    } else {
                        setSubLabel($.Rez.Strings.PotentialError);
                    }
                } else {
                    // The template must return a Lang.String, a number can be either integer or float and hence cannot be formatted locally without error.
                    setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
                }
                requestUpdate();
                if (mCallback != null) {
                    mCallback.invoke();
                }
                break;

            default:
                // System.println("TemplateMenuItem onReturnGetState(): Unhandled HTTP response code = " + responseCode);
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
        getApp().setApiStatus(status);
    }

    function getState() as Void {
        if (mTemplate == null) {
            // Nothing to do here.
            if (mCallback != null) {
                mCallback.invoke();
            }
        } else {
            if (! System.getDeviceSettings().phoneConnected) {
                // System.println("TemplateMenuItem getState(): No Phone connection, skipping API call.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
                getApp().setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
            } else if (! System.getDeviceSettings().connectionAvailable) {
                // System.println("TemplateMenuItem getState(): No Internet connection, skipping API call.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String + ".");
                getApp().setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
            } else {
                // https://developers.home-assistant.io/docs/api/native-app-integration/sending-data/#render-templates
                var url = Settings.getApiUrl() + "/webhook/" + Settings.getWebhookId();
                // System.println("TemplateMenuItem getState() URL=" + url + ", Template='" + mTemplate + "'");
                Communications.makeWebRequest(
                    url,
                    {
                        "type" => "render_template",
                        "data" => {
                            "request" => {
                                "template" => mTemplate
                            }
                        }
                    },
                    {
                        :method       => Communications.HTTP_REQUEST_METHOD_POST,
                        :headers      => {
                            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                        },
                        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                    },
                    method(:onReturnGetState)
                );
            }
        }
    }

    function hasTemplate() as Lang.Boolean {
        return (mTemplate != null);
    }

}
