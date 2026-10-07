import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioSessionChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAudioSessionChannel(engineBridge)
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
