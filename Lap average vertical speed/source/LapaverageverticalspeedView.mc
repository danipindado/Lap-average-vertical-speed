using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.Application as App;

class MyDataField extends Ui.SimpleDataField
{
    // accumulated values from before the most recent pause or stop
    hidden var _M_accumulatedTime;
    hidden var _M_accumulatedAscent;

    // values at the time of the most recent resume or start
    hidden var _M_previousTime;
    hidden var _M_previousAscent;

    hidden var _M_paused;
    hidden var app;

    hidden static const _C_scale = [
        1.0, // convert from meters to meters
        3.28084 // convert from meters to feet
    ];

    function initialize() {
        SimpleDataField.initialize();
        app = App.getApp();
        
        label = Ui.loadResource(Rez.Strings.AppName);

        // maybe this should be derived from info.timerState?
        _M_paused = true;

        _M_accumulatedTime = 0;
        _M_accumulatedAscent = 0;
    }

    function compute(info) {
        ////Sys.println("compute");

        // time in milliseconds since last start or resume
        var deltaTime   = 0;

        // ascent in meters since last start or resume
        var deltaAscent = 0;

        if (!_M_paused) {

            // guard against null since this can be called before the session
            // has started recording

            if (info.elapsedTime != null) {
                if (_M_previousTime == null) {
                    _M_previousTime = info.elapsedTime;
                }

                deltaTime = (info.elapsedTime - _M_previousTime);
            }

            if (info.totalAscent != null) {
                if (_M_previousAscent == null) {
                    _M_previousAscent = info.totalAscent;
                }

                deltaAscent = (info.totalAscent - _M_previousAscent);
            }
        }

        var deviceSettings = Sys.getDeviceSettings();

        // milliseconds to seconds
        var time = (_M_accumulatedTime + deltaTime) / 1000.0;
        if (time < 1.0) {
            return 0.0;
        }

        // seconds to hours
        time /= 3600.0;

        // meters
        var distance = (_M_accumulatedAscent + deltaAscent);

        // meters to user units (meters or feet)
        if(Sys.getDeviceSettings().elevationUnits == Sys.UNIT_METRIC)
        {
            distance *= _C_scale[0];        
        }
        else
        {
            distance *= _C_scale[1];        
        }        

        return distance / time;
    }

    hidden function pause() {

        if (_M_paused) {
            return;
        }

        _M_paused = true;

        var info = Activity.getActivityInfo();

        //
        // should not need to do null checking here since the activity
        // session should have started before being paused
        //

        _M_accumulatedTime += (info.elapsedTime - _M_previousTime);
        _M_accumulatedAscent += (info.totalAscent - _M_previousAscent);
    }

    hidden function resume() {
        _M_paused = false;

        var info = Activity.getActivityInfo();

        _M_previousTime = info.elapsedTime;
        _M_previousAscent = info.totalAscent;
    }

    hidden function reset() {
        //reset lap variables if necessary
        if(app.getProperty("lapReset"))
        {
            _M_accumulatedTime = 0;
            _M_accumulatedAscent = 0;
            _M_previousTime = null;
            _M_previousAscent = null;
        }
    }

    function onTimerStop() {
        //Sys.println("onTimerStop");
        pause();
    }

    function onTimerStart() {
        //Sys.println("onTimerStart");
        resume();
    }

    function onTimerPause() {
        //Sys.println("onTimerPause");
        pause();
    }

    function onTimerResume() {
        //Sys.println("onTimerResume");
        resume();
    }

    function onTimerReset() {
        //Sys.println("onTimerReset");
        reset();
    }

    function onTimerLap() {
        //Sys.println("onTimerLap");
        reset();
    }
}

class MyApp extends App.AppBase
{
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new MyDataField() ];
    }
}