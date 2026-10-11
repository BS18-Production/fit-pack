import ActivityKit
import Foundation

/// Canlı antrenman — kilit ekranı / Dynamic Island (docs/32, docs/45).
/// Uygulama ve widget eklentisi bu dosyayı ORTAK derler; alan adı ya da tipi
/// değişirse iki taraf birlikte güncellenir (ActivityKit JSON ile taşır).
@available(iOS 16.1, *)
struct WorkoutActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// Şu anki (sıradaki) hareket ("Barbell Bench Press").
    var exercise: String
    /// "Set 2/4".
    var setLabel: String
    /// Sıradaki setin hedefi ("80 kg × 8"); yoksa boş.
    var target: String
    /// Dinlenme başlangıcı/bitişi; dinlenme yoksa nil. Başlangıç ilerleme
    /// çubuğu için (sistem çizer, uygulama uyurken de akar).
    var restStartedAt: Date?
    var restEndsAt: Date?
    /// Tamamlanan / toplam set (ilerleme çubuğu).
    var doneSets: Int
    var totalSets: Int
    /// "Seti tamamla" düğmesi gösterilsin mi.
    var canComplete: Bool
  }

  /// Kilit ekranı metinleri — Dart'tan (.arb) gelir, seans boyunca sabit.
  public struct Labels: Codable, Hashable {
    var rest: String
    var restOver: String
    var next: String
    var completeSet: String
    var addRest: String
    var skipRest: String
    var elapsed: String
  }

  /// Seans adı ("İtme") ve başlangıcı — seans boyunca değişmez.
  var title: String
  var startedAt: Date
  var labels: Labels
}
