import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Ciclo de vida UIScene (obligatorio desde iOS 27 al compilar con el SDK
  // actual; sin él la app se cierra al abrir). El engine lo crea
  // SceneDelegate y aquí se registran los plugins cuando ya existe.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setUpPaymentCaptureChannel(registry: engineBridge.pluginRegistry)
    // La acción "Registrar pago" de Atajos puede ejecutarse con la app
    // abierta: avisar a Flutter para que lo registre al instante.
    NotificationCenter.default.addObserver(
      forName: PaymentCaptureQueue.didEnqueue,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.paymentCaptureChannel?.invokeMethod("onPaymentCaptured", arguments: nil)
    }
  }

  // MARK: - Registro automático de pagos (Apple Pay vía Atajos)
  //
  // iOS no permite leer notificaciones de otras apps. En su lugar, el usuario
  // crea en Atajos una automatización "Transacción" (se dispara al pagar con
  // Apple Pay) con la acción "Registrar pago" (RegisterPaymentIntent). Por
  // compatibilidad también se acepta el URL
  //   personalfinance://pago?monto=<Importe>&comercio=<Comercio>
  // Los pagos van a PaymentCaptureQueue y Flutter los lee con `drainPending`.

  private var paymentCaptureChannel: FlutterMethodChannel?

  private func setUpPaymentCaptureChannel(registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "PaymentCapture") else { return }
    let channel = FlutterMethodChannel(
      name: "personal_finance/payment_capture",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "drainPending":
        result(PaymentCaptureQueue.drain())
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

  /// Devuelve `true` si el URL era un pago del atajo (`personalfinance://`).
  @discardableResult
  func handlePaymentURL(_ url: URL) -> Bool {
    guard url.scheme?.lowercased() == "personalfinance" else { return false }
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    func value(_ names: [String]) -> String? {
      items.first { names.contains($0.name.lowercased()) }?.value
    }
    guard let amount = value(["monto", "amount"]), !amount.isEmpty else { return true }

    let kind = url.host?.lowercased() == "ingreso" ? "ingreso" : (value(["tipo", "type"]) ?? "gasto")
    // "+" en la URL equivale a un espacio ("Super+La+Torre").
    let merchant = (value(["comercio", "merchant"]) ?? "").replacingOccurrences(of: "+", with: " ")
    PaymentCaptureQueue.enqueue(amount: amount, merchant: merchant, kind: kind)
    return true
  }

  // MARK: - URL callback handling
  //
  // Con UIScene, iOS entrega los URLs a SceneDelegate. Este override queda
  // por compatibilidad; el resto de URLs (p. ej. OAuth) siguen a `super`.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if handlePaymentURL(url) { return true }
    return super.application(app, open: url, options: options)
  }
}
