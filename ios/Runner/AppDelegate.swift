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
    setUpPaymentCaptureChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Registro automático de pagos (Apple Pay vía Atajos)
  //
  // iOS no permite leer notificaciones de otras apps. En su lugar, el usuario
  // crea en Atajos una automatización "Transacción" (se dispara al pagar con
  // Apple Pay) que abre:
  //   personalfinance://pago?monto=<Importe>&comercio=<Comercio>
  // Los pagos se encolan aquí y Flutter los lee con `drainPending`.

  private let paymentCaptureQueueKey = "payment_capture_queue"
  private var paymentCaptureChannel: FlutterMethodChannel?

  private func setUpPaymentCaptureChannel() {
    guard let registrar = self.registrar(forPlugin: "PaymentCapture") else { return }
    let channel = FlutterMethodChannel(
      name: "personal_finance/payment_capture",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "drainPending":
        result(self?.drainPaymentCaptures() ?? [])
      case "isAccessGranted":
        // No requiere permiso: depende de que el usuario configure el atajo.
        result(true)
      case "openAccessSettings":
        if let url = URL(string: "shortcuts://") {
          UIApplication.shared.open(url)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    paymentCaptureChannel = channel
  }

  private func handlePaymentURL(_ url: URL) {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    func value(_ names: [String]) -> String? {
      items.first { names.contains($0.name.lowercased()) }?.value
    }
    guard let amount = value(["monto", "amount"]), !amount.isEmpty else { return }

    let kind = url.host?.lowercased() == "ingreso" ? "ingreso" : (value(["tipo", "type"]) ?? "gasto")
    let capture: [String: Any] = [
      "source": "shortcut",
      "packageName": "apple_pay",
      "title": "",
      "text": "",
      "amount": amount,
      "merchant": value(["comercio", "merchant"]) ?? "",
      "kind": kind,
      "postedAt": Int64(Date().timeIntervalSince1970 * 1000),
    ]
    var queue = UserDefaults.standard.array(forKey: paymentCaptureQueueKey) as? [[String: Any]] ?? []
    queue.append(capture)
    if queue.count > 100 { queue.removeFirst(queue.count - 100) }
    UserDefaults.standard.set(queue, forKey: paymentCaptureQueueKey)
    paymentCaptureChannel?.invokeMethod("onPaymentCaptured", arguments: nil)
  }

  private func drainPaymentCaptures() -> [[String: Any]] {
    let queue = UserDefaults.standard.array(forKey: paymentCaptureQueueKey) as? [[String: Any]] ?? []
    UserDefaults.standard.removeObject(forKey: paymentCaptureQueueKey)
    return queue
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
    if url.scheme?.lowercased() == "personalfinance" {
      handlePaymentURL(url)
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
