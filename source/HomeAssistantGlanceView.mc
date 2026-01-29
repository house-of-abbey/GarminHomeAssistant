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
// P A Abbey & J D Abbey & Someone0nEarth, 23 November 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

//! Glance view for GarminHomeAssistant
//
(:glance)
class HomeAssistantGlanceView extends WatchUi.GlanceView {
    //! Margin left of the filled rectangle in pixels.
    private static const scLeftRectMargin    =  5;
    //! Filled rectangle width in pixels.
    private static const scRectWidth         = 20;
    //! Margin right of the filled rectangle in pixels.
    private static const scRightRectMargin   =  5;
    //! Separator between the first column of text and the second in pixels.
    //! i.e. Middle Separator "text:_text"
    private static const scMidSep            = 10;
    //! Margin on the right side of the glance in pixels.
    private static const scRightGlanceMargin = 15;
    //! Internal margin for the custom template between the border and the text in pixels.
    private static const scIntCustMargin     =  5;
    //! Margin top and bottom of the rectangles in pixels.
    private static const scVertMargin        =  5;
    //! Size of the rounded rectangle corners in pixels.
    private static const scRectRadius        =  5;

    //! Dynamically scale the width of the first column of text based on the
    //! language selection for the word "Menu".
    private var mTextWidth     as Lang.Number  = 0;
    // Re-usable text items for drawing
    private var mApp           as HomeAssistantApp;
    private var mTitle         as WatchUi.Text?;
    private var mApiText       as WatchUi.Text?;
    private var mApiStatus     as WatchUi.Text?;
    private var mMenuText      as WatchUi.Text?;
    private var mMenuStatus    as WatchUi.Text?;
    private var mGlanceContent as WatchUi.TextArea?;
    private var mAntiAlias     as Lang.Boolean = false;

    //! Class Constructor
    //
    function initialize(app as HomeAssistantApp) {
        GlanceView.initialize();
        mApp = app;
        if (Graphics.Dc has :setAntiAlias) {
            mAntiAlias = true;
        }
    }

    //! Construct the view.
    //!
    //! @param dc Device context
    //
    function onLayout(dc as Graphics.Dc) as Void {
        var h = dc.getHeight();

        mTextWidth = dc.getTextWidthInPixels(WatchUi.loadResource($.Rez.Strings.GlanceMenu) as Lang.String + ":", Graphics.FONT_XTINY);

        mTitle = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.AppName) as Lang.String,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_TINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftRectMargin,
            :locY          => 1 * h / 6
        });

        mApiText = new WatchUi.Text({
            :text          => "API:",
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftRectMargin + scRectWidth + scRightRectMargin,
            :locY          => 3 * h / 6
        });
        mApiStatus = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftRectMargin + scRectWidth + scRightRectMargin + scMidSep + mTextWidth,
            :locY          => 3 * h / 6
        });

        mMenuText = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.GlanceMenu) as Lang.String + ":",
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftRectMargin + scRectWidth + scRightRectMargin,
            :locY          => 5 * h / 6
        });
        mMenuStatus = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftRectMargin + scRectWidth + scRightRectMargin + scMidSep + mTextWidth,
            :locY          => 5 * h / 6
        });

        mGlanceContent = new WatchUi.TextArea({
            :text          => "A longer piece of text to wrap.",
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftRectMargin + scRectWidth + scRightRectMargin + scIntCustMargin,
            :locY          => (2 * h / 6) + scVertMargin,
            :width         => dc.getWidth() - scLeftRectMargin - scRectWidth - scRightRectMargin - (2 * scIntCustMargin) - scRightGlanceMargin,
            :height        => (4 * h / 6) - (2 * scVertMargin)
        });
    }

    //! Update the view with the latest status text.
    //!
    //! @param dc Device context
    //
    function onUpdate(dc as Graphics.Dc) as Void {
        var h          = dc.getHeight();
        var w          = dc.getWidth() - scLeftRectMargin - scRightGlanceMargin;
        var apiStatus  = mApp.getApiStatus();
        var menuStatus = mApp.getMenuStatus();
        var glanceText = mApp.getGlanceText();
        var apiCol;
        var menuCol;
        // System.println("HomeAssistantGlanceView onUpdate() glanceText=" + glanceText);

        GlanceView.onUpdate(dc);
        if (mAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.clear();
        mTitle.setColor(Graphics.COLOR_BLUE);
        mTitle.draw(dc);

        if (apiStatus.equals(WatchUi.loadResource($.Rez.Strings.Checking))) {
            apiCol = Graphics.COLOR_YELLOW;
        } else if (apiStatus.equals(WatchUi.loadResource($.Rez.Strings.Available))) {
            apiCol = Graphics.COLOR_GREEN;
        } else {
            apiCol = Graphics.COLOR_RED;
        }

        if (menuStatus.equals(WatchUi.loadResource($.Rez.Strings.Checking))) {
            menuCol = Graphics.COLOR_YELLOW;
        } else if (menuStatus.equals(WatchUi.loadResource($.Rez.Strings.Available))) {
            menuCol = Graphics.COLOR_GREEN;
        } else if (menuStatus.equals(WatchUi.loadResource($.Rez.Strings.Cached))) {
            menuCol = Graphics.COLOR_GREEN;
        } else {
            menuCol = Graphics.COLOR_RED;
        }

        if (glanceText == null) {
            // Default Glance View
            mApiText.draw(dc);
            mApiStatus.setText(apiStatus);
            mApiStatus.setColor(apiCol);
            dc.setColor(apiCol, apiCol);
            dc.drawRoundedRectangle(scLeftRectMargin, 2 * h / 6 + scVertMargin, w,           2 * h / 6 - (2 * scVertMargin), scRectRadius);
            dc.fillRoundedRectangle(scLeftRectMargin, 2 * h / 6 + scVertMargin, scRectWidth, 2 * h / 6 - (2 * scVertMargin), scRectRadius);
            mApiStatus.draw(dc);

            mMenuText.draw(dc);
            mMenuStatus.setText(menuStatus);
            mMenuStatus.setColor(menuCol);
            dc.setColor(menuCol, menuCol);
            dc.drawRoundedRectangle(scLeftRectMargin, 4 * h / 6 + scVertMargin, w,           2 * h / 6 - (2 * scVertMargin), scRectRadius);
            dc.fillRoundedRectangle(scLeftRectMargin, 4 * h / 6 + scVertMargin, scRectWidth, 2 * h / 6 - (2 * scVertMargin), scRectRadius);
            mMenuStatus.draw(dc);
        } else {
            // Customised Glance View
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.drawRoundedRectangle(
                scLeftRectMargin + scRectWidth + scRightRectMargin,
                2 * h / 6 + scVertMargin,
                w - scRectWidth - scRightRectMargin,
                4 * h / 6 - (2 * scVertMargin),
                scRectRadius
            );
            dc.setColor(apiCol, apiCol);
            dc.fillRoundedRectangle(scLeftRectMargin, 2 * h / 6 + scVertMargin, scRectWidth, 2 * h / 6 - (2 * scVertMargin), scRectRadius);
            dc.setColor(menuCol, menuCol);
            dc.fillRoundedRectangle(scLeftRectMargin, 4 * h / 6 + scVertMargin, scRectWidth, 2 * h / 6 - (2 * scVertMargin), scRectRadius);
            mGlanceContent.setText(glanceText);
            mGlanceContent.draw(dc);
        }
   }
}
