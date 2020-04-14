using Toybox.Application;

class MiniDashApp extends Application.AppBase {

    hidden var datafieldView;
    
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    	datafieldView = [ new MiniDashView() ];
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return datafieldView;
    }
    
    // Create new Kalman Filter upon onSettingsChanged
    function onSettingsChanged() {
    	datafieldView[0].updateSettings();
    }  

}