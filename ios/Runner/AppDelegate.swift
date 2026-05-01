import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Patrón estándar de Flutter: registrar todos los plugins generados aquí.
    // Compatible con todas las versiones de Flutter en el canal stable.
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - URL callback handling
  //
  // El plugin `google_sign_in` en iOS responde al callback OAuth a través del
  // URL scheme declarado en Info.plist (CFBundleURLSchemes). `FlutterAppDelegate`
  // reenvía automáticamente el URL a los plugins registrados; este override
  // garantiza que se llame a `super` (compatibilidad defensiva).
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
