import Flutter
import UIKit
import GoogleMaps
import CoreLocation
import Foundation
import os.log

//let methodChannelName = "com.cycleguard.channel" // Must match Dart

// for local notifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // for local notifications
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in 
        GeneratedPluginRegistrant.register(with: registry)}

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        // Register your MethodChannel if needed, then:
        //GMSServices.provideAPIKey("AIzaSyCZElHjb6lqVO5AQQvhaA0nn1f8bL7HD3k")

        // Register MethodChannel in LocationManager
        // LocationManager.shared.registerMethodChannel(with: controller.binaryMessenger)
        
        // Request location permission using LocationManager
        // LocationManager.shared.requestLocationPermission()

        GeneratedPluginRegistrant.register(with: self)

        // for local notifications
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        // provide Google Maps API Key
        GMSServices.provideAPIKey("AIzaSyCZElHjb6lqVO5AQQvhaA0nn1f8bL7HD3k")
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
