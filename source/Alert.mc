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

class Alert extends WatchUi.View {
    private static const bRadius = 10;
    private var mTimer   as Timer.Timer;
    private var mTimeout as Lang.Number;
    private var mText    as Lang.String;
    private var mFont    as Graphics.FontType;
    private var mFgcolor as Graphics.ColorType;
    private var mBgcolor as Graphics.ColorType;

    function initialize(params as Lang.Dictionary) {
        View.initialize();

        mText = params.get(:text) as Lang.String;
        if (mText == null) {
            mText = "Alert";
        }

        mFont = params.get(:font) as Graphics.FontType;
        if (mFont == null) {
            mFont = Graphics.FONT_MEDIUM;
        }

        mFgcolor = params.get(:fgcolor) as Graphics.ColorType;
        if (mFgcolor == null) {
            mFgcolor = Graphics.COLOR_BLACK;
        }

        mBgcolor = params.get(:bgcolor) as Graphics.ColorType;
        if (mBgcolor == null) {
            mBgcolor = Graphics.COLOR_WHITE;
        }

        mTimeout = params.get(:timeout) as Lang.Number;
        if (mTimeout == null) {
            mTimeout = 2000;
        }

        mTimer = new Timer.Timer();
    }

    function onShow() {
        mTimer.start(method(:dismiss), mTimeout, false);
    }

    function onHide() {
        mTimer.stop();
    }

    function onUpdate(dc) {
        var tWidth  = dc.getTextWidthInPixels(mText, mFont);
        var tHeight = dc.getFontHeight(mFont);
        var bWidth  = tWidth  + 20;
        var bHeight = tHeight + 15;
        var bX      = (dc.getWidth()  - bWidth)  / 2;
        var bY      = (dc.getHeight() - bHeight) / 2;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.clear();
        dc.setColor(mBgcolor, mBgcolor);
        dc.fillRoundedRectangle(bX, bY, bWidth, bHeight, bRadius);

        dc.setColor(mFgcolor, mBgcolor);
        for (var i = 0; i < 3; ++i) {
            bX      += i;
            bY      += i;
            bWidth  -= (2 * i);
            bHeight -= (2 * i);
            dc.drawRoundedRectangle(bX, bY, bWidth, bHeight, bRadius);
        }

        var tX = dc.getWidth() / 2;
        var tY = bY + bHeight  / 2;
        dc.setColor(mFgcolor, mBgcolor);
        dc.drawText(tX, tY, mFont, mText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Remove the alert from view, usually on user input, but that is defined by the calling function.
    //
    function dismiss() as Void {
        WatchUi.popView(SLIDE_IMMEDIATE);
    }

    function pushView(transition) as Void {
        WatchUi.pushView(self, new AlertDelegate(self), transition);
    }
}

class AlertDelegate extends WatchUi.InputDelegate {
    private var mView;

    function initialize(view) {
        InputDelegate.initialize();
        mView = view;
    }

    function onKey(evt) as Lang.Boolean {
        mView.dismiss();
        getApp().getQuitTimer().reset();
        return true;
    }

    function onTap(evt) as Lang.Boolean {
        mView.dismiss();
        getApp().getQuitTimer().reset();
        return true;
    }
}
