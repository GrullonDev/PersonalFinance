import Flutter
import UIKit

/// Escena principal (ciclo de vida UIScene). `FlutterSceneDelegate` crea la
/// ventana y el engine; aquí sólo interceptamos los URLs del atajo de
/// Apple Pay (`personalfinance://pago?...`) y dejamos el resto a Flutter.
class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // App abierta en frío desde el atajo: el pago queda en cola y Flutter
    // lo lee con `drainPending` al arrancar.
    for context in connectionOptions.urlContexts {
      paymentHandler?.handlePaymentURL(context.url)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let others = URLContexts.filter { !(paymentHandler?.handlePaymentURL($0.url) ?? false) }
    if !others.isEmpty {
      super.scene(scene, openURLContexts: others)
    }
  }

  private var paymentHandler: AppDelegate? {
    UIApplication.shared.delegate as? AppDelegate
  }
}
