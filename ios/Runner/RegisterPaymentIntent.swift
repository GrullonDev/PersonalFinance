import AppIntents
import Foundation

/// Acción de Atajos "Registrar pago".
///
/// Se usa en la automatización "Transacción" de Wallet: el usuario elige las
/// variables Importe y Comerciante y el pago queda en cola sin abrir la app
/// (ni armar URLs). Flutter lo registra la próxima vez que la app está activa.
@available(iOS 16.0, *)
struct RegisterPaymentIntent: AppIntent {
  static var title: LocalizedStringResource = "Registrar pago"
  static var description = IntentDescription(
    "Registra un gasto o ingreso en tus finanzas (por ejemplo, un pago con Apple Pay)."
  )
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Monto", description: "Importe del pago, por ejemplo Q44.00")
  var monto: String

  @Parameter(title: "Comercio", description: "Dónde se pagó")
  var comercio: String?

  @Parameter(title: "Es ingreso", default: false)
  var esIngreso: Bool

  static var parameterSummary: some ParameterSummary {
    Summary("Registrar \(\.$monto) en \(\.$comercio)") {
      \.$esIngreso
    }
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    PaymentCaptureQueue.enqueue(
      amount: monto,
      merchant: comercio ?? "",
      kind: esIngreso ? "ingreso" : "gasto"
    )
    let lugar = (comercio?.isEmpty == false) ? " en " + (comercio ?? "") : ""
    let mensaje = "Pago de " + monto + lugar + " registrado."
    return .result(dialog: IntentDialog(stringLiteral: mensaje))
  }
}

@available(iOS 16.0, *)
struct PersonalFinanceShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RegisterPaymentIntent(),
      phrases: ["Registrar pago en \(.applicationName)"]
    )
  }
}
