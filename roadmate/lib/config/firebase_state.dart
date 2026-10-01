/// Tracks whether Firebase initialised at startup.
///
/// `main()` sets this after `Firebase.initializeApp()`. Auth screens check
/// it to show a setup hint instead of failing when google-services config
/// files haven't been added yet.
library;

bool firebaseReady = false;
