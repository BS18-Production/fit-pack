import AppIntents
import Foundation

/// Kilit ekranı düğmeleri (docs/45 §2) — iOS 17+ `LiveActivityIntent`.
///
/// Dosya İKİ hedefte derlenir: eklenti düğmeyi çizer, `perform` ise
/// **uygulama sürecinde** çalışır (sistem uygulamayı arka planda uyandırır,
/// arayüzü öne açmaz). Kilit doğrulaması sistemin yüzey politikasına bağlıdır.
/// Uygulama eylemi Dart'taki açık seans ekranına iletir —
/// seans durumunun tek sahibi orası; burada durum tutulmaz.
enum LiveActivityActionRouter {
  /// Uygulama hedefinde `AppDelegate` kurar; eklentide nil kalır.
  /// (eylem adı, set veya mola sürümü)
  @MainActor static var handler: (@MainActor (String, String) async -> Bool)?

  @MainActor static func run(_ action: String, setKey: String = "") async {
    guard let handler else { return }
    _ = await handler(action, setKey)
  }
}

/// Seti tamamla — kartın gösterdiği sete bağlı ([setKey]); arada set
/// değiştiyse uygulama eylemi yok sayar (gecikmiş/çift dokunuş).
@available(iOS 17.0, *)
struct CompleteSetIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Complete set"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Set")
  var setKey: String

  init() {}
  init(setKey: String) { self.setKey = setKey }

  func perform() async throws -> some IntentResult {
    await LiveActivityActionRouter.run("completeSet", setKey: setKey)
    return .result()
  }
}

/// Kilo adımı / ±1 tekrar — yalnız kartın gösterdiği setin tek alanı.
@available(iOS 17.0, *)
struct StepSetIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Adjust set"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Set")
  var setKey: String

  @Parameter(title: "Up")
  var up: Bool

  init() {}
  init(setKey: String, up: Bool) {
    self.setKey = setKey
    self.up = up
  }

  func perform() async throws -> some IntentResult {
    await LiveActivityActionRouter.run(up ? "stepUp" : "stepDown", setKey: setKey)
    return .result()
  }
}

@available(iOS 17.0, *)
struct AddRestIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Add 15 seconds"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Rest")
  var restKey: String

  init() { self.restKey = "" }
  init(restKey: String) { self.restKey = restKey }

  func perform() async throws -> some IntentResult {
    await LiveActivityActionRouter.run("addRest", setKey: restKey)
    return .result()
  }
}

@available(iOS 17.0, *)
struct SkipRestIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Skip rest"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Rest")
  var restKey: String

  init() { self.restKey = "" }
  init(restKey: String) { self.restKey = restKey }

  func perform() async throws -> some IntentResult {
    await LiveActivityActionRouter.run("skipRest", setKey: restKey)
    return .result()
  }
}
