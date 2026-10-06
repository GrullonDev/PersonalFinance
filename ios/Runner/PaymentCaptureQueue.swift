import Foundation

/// Cola de pagos capturados en iOS (atajo de Apple Pay / acción "Registrar
/// pago"). Se guarda en UserDefaults para no perder pagos aunque la app esté
/// cerrada; Flutter la vacía con `drainPending`.
enum PaymentCaptureQueue {
  static let didEnqueue = Notification.Name("PaymentCaptureQueue.didEnqueue")
  private static let key = "payment_capture_queue"
  private static let maxItems = 100

  static func enqueue(amount: String, merchant: String, kind: String) {
    let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let capture: [String: Any] = [
      "source": "shortcut",
      "packageName": "apple_pay",
      "title": "",
      "text": "",
      "amount": trimmed,
      "merchant": merchant.trimmingCharacters(in: .whitespacesAndNewlines),
      "kind": kind.lowercased(),
      "postedAt": Int64(Date().timeIntervalSince1970 * 1000),
    ]
    let defaults = UserDefaults.standard
    var queue = defaults.array(forKey: key) as? [[String: Any]] ?? []
    queue.append(capture)
    if queue.count > maxItems { queue.removeFirst(queue.count - maxItems) }
    defaults.set(queue, forKey: key)
    NotificationCenter.default.post(name: didEnqueue, object: nil)
  }

  static func drain() -> [[String: Any]] {
    let defaults = UserDefaults.standard
    let queue = defaults.array(forKey: key) as? [[String: Any]] ?? []
    defaults.removeObject(forKey: key)
    return queue
  }
}
