import UIKit
import Flutter
import GoogleMaps // BU SATIRI EKLE

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // BU SATIRI EKLE VE KEY'İNİ YAPIŞTIR
    GMSServices.provideAPIKey("AIzaSyD1jMfJXa5-HblokvBDHAeKvUea_3jPDeI")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}