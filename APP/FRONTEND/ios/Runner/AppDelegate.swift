import Flutter
import UIKit
import GoogleMaps // Import the Google Maps SDK

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps SDK with your API key
    GMSServices.provideAPIKey("AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco") // Replace with your actual API key

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
