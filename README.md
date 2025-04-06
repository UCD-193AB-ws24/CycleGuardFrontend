# CycleGuard Frontend

The CycleGuard mobile application is developed in Dart with the Flutter 3.27.3 framework. We are developing it using Android Studio.

## Setup

1. Clone this repository into a folder, and open in Android Studio. It requires the [official Flutter add-on](https://plugins.jetbrains.com/plugin/9212-flutter).
2. Run `flutter get` to retrieve dependencies, or click the pop-up prompt in the IDE.
3. Select your device, either in-browser or on (virtual) mobile. We are developing for mobile only.
4. Run the project. Make sure the virtual device has permission to make HTTP requests.
> For example, for Android, put `<uses-permission android:name="android.permission.INTERNET"/>` within `AndroidManifest.xml`.

### Requirements

CycleGuard requires Internet and Bluetooth access, and these must be enabled to use full app functionality.

### Dependencies

> cupertino_icons: ^1.0.8
> 
> provider: ^6.1.2
> 
> fl_chart: ^0.70.2
> 
> flutter_native_splash: ^2.1.2
> 
> smooth_page_indicator: ^1.1.0
> 
> get: ^4.6.5
> 
> get_storage: ^2.1.1
> 
> google_fonts: ^6.1.0
> 
> fluttertoast: ^8.2.11
