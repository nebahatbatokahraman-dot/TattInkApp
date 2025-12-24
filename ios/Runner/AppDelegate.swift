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
    GMSServices.provideAPIKey("AIzaSyCWa38yCMYv9GRrj5_SPdGgmSYM55BdYBU")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}