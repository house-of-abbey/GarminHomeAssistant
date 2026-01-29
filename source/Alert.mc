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

using Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Timer;

//! The Alert class provides a means to present application notifications to the user
//! briefly. Credit to travis.vitek on forums.garmin.com.
//!
//! Reference:
//!  @url https://forums.garmin.com/developer/connect-iq/f/discussion/106/how-to-show-alert-messages
//
class Alert extends WatchUi.View {
    private static const scRadius = 10;
    private var mTimer   as Timer.Timer;
    private var mTimeout as Lang.Number;
    private var mText    as Lang.String;
    private var mFont    as Graphics.FontType;
    private var mFgcolor as Graphics.ColorType;
    private var mBgcolor as Graphics.ColorType;

    //! Class Constructor
    //! @param params A dictionary object as follows:<br>
    //!   `{`<br>
    //!   &emsp; `:timeout as Lang.Number,`        // Timeout in millseconds<br>
    //!   &emsp; `:font    as Graphics.FontType,`  // Text font size<br>
    //!   &emsp; `:text    as Lang.String,`        // Text to display<br>
    //!   &emsp; `:fgcolor as Graphics.ColorType,` // Foreground Colour<br>
    //!   &emsp; `:bgcolor as Graphics.ColorType`  // Background Colour<br>
    //!   `}`
    //
    function initialize(params as Lang.Dictionary) {
        View.initialize();

        mText = params[:text] as Lang.String?;
        if (mText == null) {
            mText = "Alert";
        }

        mFont = params[:font] as Graphics.FontType?;
        if (mFont == null) {
            mFont = Graphics.FONT_MEDIUM;
        }

        mFgcolor = params[:fgcolor] as Graphics.ColorType?;
        if (mFgcolor == null) {
            mFgcolor = Graphics.COLOR_BLACK;
        }

        mBgcolor = params[:bgcolor] as Graphics.ColorType?;
        if (mBgcolor == null) {
            mBgcolor = Graphics.COLOR_WHITE;
        }

        mTimeout = params[:timeout] as Lang.Number?;
        if (mTimeout == null) {
            mTimeout = 2000;
        }

        mTimer = new Timer.Timer();
    }

    //! Setup a timer to dismiss the alert.
    //
    function onShow() {
        mTimer.start(method(:dismiss), mTimeout, false);
    }

    //! Prematurely stop the timer.
    //
    function onHide() {
        mTimer.stop();
    }

    //! Draw the Alert view.
    //!
    //! @param dc Device context
    //
    function onUpdate(dc as Graphics.Dc) {
        var tWidth  = dc.getTextWidthInPixels(mText, mFont);
        var tHeight = dc.getFontHeight(mFont);
        var bWidth  = tWidth  + 20;
        var bHeight = tHeight + 15;
        var bX      = (dc.getWidth()  - bWidth)  / 2;
        var bY      = (dc.getHeight() - bHeight) / 2;

        if (Graphics.Dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.clear();
        dc.setColor(mBgcolor, mBgcolor);
        dc.fillRoundedRectangle(bX, bY, bWidth, bHeight, scRadius);

        dc.setColor(mFgcolor, mBgcolor);
        for (var i = 0; i < 3; ++i) {
            bX      += i;
            bY      += i;
            bWidth  -= (2 * i);
            bHeight -= (2 * i);
            dc.drawRoundedRectangle(bX, bY, bWidth, bHeight, scRadius);
        }

        var tX = dc.getWidth() / 2;
        var tY = bY + bHeight  / 2;
        dc.setColor(mFgcolor, mBgcolor);
        dc.drawText(tX, tY, mFont, mText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Remove the alert from view, usually on user input, but that is defined by the calling function.
    //
    function dismiss() as Void {
        WatchUi.popView(SLIDE_IMMEDIATE);
    }

    //! Push this view onto the view stack.
    //!
    //! @param transition Slide Type
    function pushView(transition as WatchUi.SlideType) as Void {
        WatchUi.pushView(self, new AlertDelegate(self), transition);
    }
}

//! Input Delegate for the Alert view.
//
class AlertDelegate extends WatchUi.InputDelegate {
    private var mView as Alert;

    //! Class Constructor
    //!
    //! @param view The Alert view for which this class is a delegate.
    //!
    function initialize(view as Alert) {
        InputDelegate.initialize();
        mView = view;
    }

    //! Handle key events.
    //!
    //! @param evt The key event whose value is ignored, just fact of key event matters.
    //!
    function onKey(evt as WatchUi.KeyEvent) as Lang.Boolean {
        mView.dismiss();
        getApp().getQuitTimer().reset();
        return true;
    }

    //! Handle click events.
    //!
    //! @param evt The click event whose value is ignored, just fact of key event matters.
    //!
    function onTap(evt as WatchUi.ClickEvent) as Lang.Boolean {
        mView.dismiss();
        getApp().getQuitTimer().reset();
        return true;
    }
}
