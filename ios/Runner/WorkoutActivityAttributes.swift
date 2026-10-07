import ActivityKit
import Foundation

/// Canlı antrenman — kilit ekranı / Dynamic Island (docs/32).
/// Uygulama ve widget eklentisi bu dosyayı ORTAK derler; alan adı ya da tipi
/// değişirse iki taraf birlikte güncellenir (ActivityKit JSON ile taşır).
@available(iOS 16.1, *)
struct WorkoutActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// Şu anki hareket ("Barbell Bench Press").
    var exercise: String
    /// "Set 2/4".
    var setLabel: String
    /// Sıradaki setin hedefi ("80 kg × 8"); yoksa boş.
    var target: String
    /// Dinlenme bitişi; dinlenme yoksa nil.
    var restEndsAt: Date?
    /// Tamamlanan / toplam set (ilerleme çubuğu).
    var doneSets: Int
    var totalSets: Int
  }

  /// Seans adı ("İtme") ve başlangıcı — seans boyunca değişmez.
  var title: String
  var startedAt: Date
}
