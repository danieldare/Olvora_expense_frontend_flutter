import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // World-class: log uncaught native exceptions so we can fix config (e.g. GIDClientID, URL schemes)
    // Note: App may still terminate after this; the fix is to ensure Firebase/Google config is correct.
    NSSetUncaughtExceptionHandler { exception in
      let reason = exception.reason ?? "Unknown"
      let name = exception.name.rawValue
      NSLog("Olvora: Uncaught exception %@ - %@", name, reason)
      let symbols = exception.callStackSymbols.prefix(20).joined(separator: "\n")
      NSLog("Olvora: Call stack:\n%@", symbols)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
