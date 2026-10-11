import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioSessionChannel: FlutterMethodChannel?
  private var liveActivityChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAudioSessionChannel(engineBridge)
    registerLiveActivityChannel(engineBridge)
  }

  /// Canlı antrenman kilit ekranı (docs/32): Dart seans durumunu gönderir,
  /// burada ActivityKit etkinliği başlatılır / güncellenir / bitirilir.
  /// iOS 16.2 altı ya da kullanıcı Canlı Etkinlikler'i kapattıysa sessizce
  /// atlanır — seans normal çalışır.
  private func registerLiveActivityChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FitPackLiveActivity")
    else { return }
    let channel = FlutterMethodChannel(
      name: "fit_pack/live_activity", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard #available(iOS 16.2, *) else {
        result(false)
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      // İkisi de tekil: aynı seansın kartı varsa günceller (docs/45 §1).
      case "start", "update":
        WorkoutLiveActivityController.upsert(args: args)
        result(true)
      case "end":
        WorkoutLiveActivityController.endAll()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    liveActivityChannel = channel
    registerLiveActivityActions(channel)
  }

  /// Kilit ekranı düğmeleri (iOS 17+, `WorkoutLiveActivityIntents.swift`):
  /// eylem Dart'taki açık seansa iletilir, cevap beklenir (en çok 8 sn),
  /// sonra kart güncellemesi bitene kadar beklenir — `perform` dönünce
  /// sistem uygulamayı yeniden uyutur.
  private func registerLiveActivityActions(_ channel: FlutterMethodChannel) {
    LiveActivityActionRouter.handler = { [weak channel] action, setKey in
      guard let channel else { return false }
      let applied = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
        let once = ResumeOnce(cont)
        let args: [String: Any] = ["action": action, "setKey": setKey]
        channel.invokeMethod("action", arguments: args) { reply in
          once.resume(reply as? Bool ?? false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { once.resume(false) }
      }
      if #available(iOS 16.2, *) {
        await WorkoutLiveActivityController.drain()
      }
      return applied
    }
  }

  /// Mola geri sayım sesi müziği kısarak (duckOthers) çalar. audioplayers ses
  /// bitince oturumu kapatmıyor → müzik kısık kalıyordu (Samet, 2026-10-07).
  /// Dart ses bitince "release" çağırır: oturum kapanır, diğer uygulamalara
  /// haber verilir ve müzik eski seviyesine döner.
  private func registerAudioSessionChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FitPackAudioSession")
    else { return }
    let channel = FlutterMethodChannel(
      name: "fit_pack/audio_session", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "release" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        try AVAudioSession.sharedInstance().setActive(
          false, options: .notifyOthersOnDeactivation)
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "audio_session", message: error.localizedDescription, details: nil))
      }
    }
    audioSessionChannel = channel
  }
}

/// Devamı tek kez sürdürür: Dart cevabı ile zaman aşımı yarışır (ikisi de
/// ana iş parçacığında çağrılır).
private final class ResumeOnce {
  private var continuation: CheckedContinuation<Bool, Never>?

  init(_ continuation: CheckedContinuation<Bool, Never>) {
    self.continuation = continuation
  }

  func resume(_ value: Bool) {
    continuation?.resume(returning: value)
    continuation = nil
  }
}
