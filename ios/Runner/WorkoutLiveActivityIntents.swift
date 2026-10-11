import AppIntents
import Foundation

/// Kilit ekranı düğmeleri (docs/45 §2) — iOS 17+ `LiveActivityIntent`.
///
/// Dosya İKİ hedefte derlenir: eklenti düğmeyi çizer, `perform` ise
/// **uygulama sürecinde** çalışır (sistem uygulamayı arka planda uyandırır,
/// kilit açılmaz). Uygulama eylemi Dart'taki açık seans ekranına iletir —
/// seans durumunun tek sahibi orası; burada durum tutulmaz.
enum LiveActivityActionRouter {
  /// Uygulama hedefinde `AppDelegate` kurar; eklentide nil kalır.
  @MainActor static var handler: (@MainActor (String) async -> Bool)?

  @MainActor static func run(_ action: String) async {
    guard let handler else { return }
    _ = await handler(action)
  }
}

@available(iOS 17.0, *)
struct CompleteSetIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Complete set"
  static var isDiscoverable: Bool = false

  init() {}

  func perform() async throws -> some IntentResult {
    await LiveActivityActionRouter.run("completeSet")
    return .result()
  }
}

@available(iOS 17.0, *)
struct AddRestIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Add 15 seconds"
  static var isDiscoverable: Bool = false

  init() {}

  func perform() async throws -> some IntentResult {
    await LiveActivityActionRouter.run("addRest")
    return .result()
  }
}

@available(iOS 17.0, *)
struct SkipRestIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Skip rest"
  static var isDiscoverable: Bool = false

  init() {}

  func perform() async throws -> some IntentResult {
    await LiveActivityActionRouter.run("skipRest")
    return .result()
  }
}
