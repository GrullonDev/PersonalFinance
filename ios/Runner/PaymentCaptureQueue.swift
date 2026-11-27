import FirebaseCore
import FirebaseAuth
import Foundation

/// Cola de pagos capturados en iOS (atajo de Wallet / acción "Registrar
/// pago"). Se guarda en un archivo protegido para no perder pagos aunque la app esté
/// cerrada; Flutter confirma cada elemento después de guardarlo.
enum PaymentCaptureQueue {
  static let didEnqueue = Notification.Name("PaymentCaptureQueue.didEnqueue")
  private static let key = "payment_capture_queue"

  private static let lock = NSLock()
  private static let ownerKey = "payment_capture_owner"
  private static let defaults = UserDefaults.standard

  @discardableResult
  static func enqueue(amount: String, merchant: String, kind: String, currency: String? = nil, fromIntent: Bool = false) -> Bool {
    let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)
    var capture: [String: Any] = [
      "source": "shortcut",
      "packageName": "wallet_shortcut",
      "title": "",
      "text": "",
      "amount": String(trimmed.prefix(64)),
      "merchant": String(merchant.trimmingCharacters(in: .whitespacesAndNewlines).prefix(160)),
      "kind": kind.lowercased(),
      "postedAt": Int64(Date().timeIntervalSince1970 * 1000),
    ]
    if let currency = currency?.trimmingCharacters(in: .whitespacesAndNewlines), !currency.isEmpty {
      capture["currency"] = String(currency.prefix(8)).uppercased()
    }
    return append(capture, fromIntent: fromIntent)
  }

  /// Mensaje de texto del banco (automatización "Mensaje" de Atajos). Flutter
  /// lo interpreta igual que una notificación de Android: gasto o ingreso,
  /// monto, comercio y categoría.
  @discardableResult
  static func enqueueMessage(sender: String, text: String) -> Bool {
    let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !body.isEmpty else { return false }
    let capture: [String: Any] = [
      "source": "notification",
      "packageName": "ios.sms",
      "title": String(sender.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
      "text": String(body.prefix(512)),
      "postedAt": Int64(Date().timeIntervalSince1970 * 1000),
    ]
    return append(capture, fromIntent: true)
  }

  private static func fileURL() throws -> URL {
    let directory = try FileManager.default.url(for: .applicationSupportDirectory,
      in: .userDomainMask, appropriateFor: nil, create: true)
    var captureDirectory = directory.appendingPathComponent("PaymentCapture", isDirectory: true)
    try FileManager.default.createDirectory(at: captureDirectory, withIntermediateDirectories: true,
      attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
    var attributes = URLResourceValues()
    attributes.isExcludedFromBackup = true
    try captureDirectory.setResourceValues(attributes)
    return captureDirectory.appendingPathComponent("queue.plist")
  }

  private static func records() throws -> [[String: Any]] {
    let url = try fileURL()
    do {
      let data = try Data(contentsOf: url)
      guard let items = try PropertyListSerialization.propertyList(from: data, format: nil)
              as? [[String: Any]] else { throw CocoaError(.fileReadCorruptFile) }
      return items
    } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
      return []
    }
  }

  private static func save(_ items: [[String: Any]]) throws {
    let data = try PropertyListSerialization.data(fromPropertyList: items, format: .binary, options: 0)
    try data.write(to: fileURL(), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  static func setOwner(_ owner: String?) {
    lock.lock()
    defer { lock.unlock() }
    // The previous queue had no owner information.
    defaults.removeObject(forKey: key)
    defaults.set(owner, forKey: ownerKey)
  }

  static func isVerified() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    guard let owner = defaults.string(forKey: ownerKey) else { return false }
    return defaults.bool(forKey: "payment_capture_verified_" + owner)
  }

  private static func append(_ capture: [String: Any], fromIntent: Bool) -> Bool {
    lock.lock()
    guard let owner = defaults.string(forKey: ownerKey), FirebaseApp.app() != nil,
          Auth.auth().currentUser?.uid == owner else {
      lock.unlock()
      return false
    }
    var item = capture
    item["id"] = UUID().uuidString
    item["owner"] = owner
    do {
      var queue = try records()
      queue.append(item)
      try save(queue)
    } catch {
      lock.unlock()
      return false
    }
    if fromIntent { defaults.set(true, forKey: "payment_capture_verified_" + owner) }
    lock.unlock()
    NotificationCenter.default.post(name: didEnqueue, object: nil)
    return true
  }

  static func peek() throws -> [[String: Any]] {
    lock.lock()
    defer { lock.unlock() }
    guard let owner = defaults.string(forKey: ownerKey) else { return [] }
    return try records().filter { $0["owner"] as? String == owner }
  }

  static func acknowledge(_ id: String) throws {
    lock.lock()
    defer { lock.unlock() }
    guard let owner = defaults.string(forKey: ownerKey) else { return }
    try save(records().filter {
      !($0["id"] as? String == id && $0["owner"] as? String == owner)
    })
  }
}
