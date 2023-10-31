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
// J D Abbey & P A Abbey, 28 December 2022
//
//
// Description:
//
// Alert provides a means to present application notifications to the user
// briefly. Credit to travis.vitek on forums.garmin.com.
//
// Reference:
//  * https://forums.garmin.com/developer/connect-iq/f/discussion/106/how-to-show-alert-messages
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Timer;

const bRadius = 10;

class Alert extends WatchUi.View {
    hidden var timer;
    hidden var timeout;
    hidden var text;
    hidden var font;
    hidden var fgcolor;
    hidden var bgcolor;

    function initialize(params as Lang.Dictionary) {
        View.initialize();

        text = params.get(:text);
        if (text == null) {
            text = "Alert";
        }

        font = params.get(:font);
        if (font == null) {
            font = Graphics.FONT_MEDIUM;
        }

        fgcolor = params.get(:fgcolor);
        if (fgcolor == null) {
            fgcolor = Graphics.COLOR_BLACK;
        }

        bgcolor = params.get(:bgcolor);
        if (bgcolor == null) {
            bgcolor = Graphics.COLOR_WHITE;
        }

        timeout = params.get(:timeout);
        if (timeout == null) {
            timeout = 2000;
        }

        timer = new Timer.Timer();
    }

    function onShow() {
        timer.start(method(:dismiss), timeout, false);
    }

    function onHide() {
        timer.stop();
    }

    function onUpdate(dc) {
        var tWidth  = dc.getTextWidthInPixels(text, font);
        var tHeight = dc.getFontHeight(font);
        var bWidth  = tWidth  + 20;
        var bHeight = tHeight + 15;
        var bX      = (dc.getWidth()  - bWidth)  / 2;
        var bY      = (dc.getHeight() - bHeight) / 2;

        if(dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.clear();
        dc.setColor(bgcolor, bgcolor);
        dc.fillRoundedRectangle(bX, bY, bWidth, bHeight, bRadius);

        dc.setColor(fgcolor, bgcolor);
        for (var i = 0; i < 3; ++i) {
            bX      += i;
            bY      += i;
            bWidth  -= (2 * i);
            bHeight -= (2 * i);
            dc.drawRoundedRectangle(bX, bY, bWidth, bHeight, bRadius);
        }

        var tX = dc.getWidth() / 2;
        var tY = bY + bHeight  / 2;
        dc.setColor(fgcolor, bgcolor);
        dc.drawText(tX, tY, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Remove the alert from view, usually on user input, but that is defined by the calling function.
    //
    function dismiss() {
        WatchUi.popView(SLIDE_IMMEDIATE);
    }

    function pushView(transition) {
        WatchUi.pushView(self, new AlertDelegate(self), transition);
    }
}

class AlertDelegate extends WatchUi.InputDelegate {
    hidden var mView;

    function initialize(view) {
        InputDelegate.initialize();
        mView = view;
    }

    function onKey(evt) {
        mView.dismiss();
        return true;
    }

    function onTap(evt) {
        mView.dismiss();
        return true;
    }
}
