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
// ErrorView provides a means to present application errors to the user. These
// should not happen of course... but they do, so best make sure errors can be
// reported.
//
// Designed so that a single ErrorView is used for all errors and hence can ensure
// that only the first call to display is honoured until the view is dismissed.
// This compensates for older devices not being able to call WatchUi.getCurrentView()
// due to not supporting API level 3.4.0.
//
// Usage:
//   1) ErrorView.show("Error message");
//   2) return ErrorView.create("Error message"); // as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Communications;

class ErrorView extends ScalableView {
    private var mText            as Lang.String = "";
    private var mDelegate        as ErrorDelegate;
    private const cSettings      as Lang.Dictionary = {
        :errorIconMargin => 7f
    };
    // Vertical spacing between the top of the face and the error icon
    private var mErrorIconMargin as Lang.Number;
    private var mErrorIcon;
    private var mTextArea;

    private static var instance;
    private static var mShown as Lang.Boolean = false;

    function initialize() {
        ScalableView.initialize();
        mDelegate = new ErrorDelegate(self);
        // Convert the settings from % of screen size to pixels
        mErrorIconMargin = pixelsForScreen(cSettings.get(:errorIconMargin) as Lang.Float);
    }

    // Load your resources here
    function onLayout(dc as Graphics.Dc) as Void {
        mErrorIcon = Application.loadResource(Rez.Drawables.ErrorIcon) as Graphics.BitmapResource;

        var w = dc.getWidth();
        var h = dc.getHeight();

        mTextArea = new WatchUi.TextArea({
            :text          => mText,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => 0,
            :locY          => 83,
            :width         => w,
            :height        => h - 166
        });
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var hw = w/2;
        var bg = 0x3B444C;
        if(dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, bg);
        dc.clear();
        dc.drawBitmap(hw - mErrorIcon.getWidth()/2, mErrorIconMargin, mErrorIcon);
        mTextArea.draw(dc);
    }

    function getDelegate() as ErrorDelegate {
        return mDelegate;
    }

    static function create(text as Lang.String) as Lang.Array<ErrorView or ErrorDelegate> {
        if (instance == null) {
            instance = new ErrorView();
        }
        if (!mShown) {
            instance.setText(text);
        }
        return [instance, instance.getDelegate()];
    }

    // Create or reuse an existing ErrorView, and pass on the text.
    static function show(text as Lang.String) as Void {
        create(text); // Ignore returned values
        if (!mShown) {
            WatchUi.pushView(instance, instance.getDelegate(), WatchUi.SLIDE_UP);
            mShown = true;
        }
    }

    // Internal show now we're not a static method like 'show()'.
    function setText(text as Lang.String) as Void {
        mText = text;
        if (mTextArea != null) {
            mTextArea.setText(text);
            requestUpdate();
        }
    }

    static function unShow() as Void {
        if (mShown) {
            mShown = false;
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

}

class ErrorDelegate extends WatchUi.BehaviorDelegate {
    //private var mView as ErrorView;

    function initialize(view as ErrorView) {
        WatchUi.BehaviorDelegate.initialize();
        //mView = view;
    }

    function onBack() {
        getApp().getQuitTimer().reset();
        ErrorView.unShow();
        return true;
    }

}