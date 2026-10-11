import ActivityKit
import Foundation

/// ActivityKit sarmalayıcısı — yalnız `AppDelegate` kanalından çağrılır.
///
/// **Tek etkinlik kuralı (docs/45 §1).** Aynı anda en fazla bir antrenman
/// etkinliği olur. İşlemler sırayla çalışır (önceki bitmeden sonraki
/// başlamaz): eskiden her çağrı ayrı `Task` açıyordu; art arda iki `start`
/// gelince ikisi de "etkinlik yok" görüp iki etkinlik istiyordu → kilit
/// ekranında iki aynı kart. `start` ve `update` artık aynı işi yapar:
/// aynı seansın (aynı başlangıç anı) etkinliği varsa günceller, yoksa
/// diğerlerini kapatıp bir tane başlatır. Uygulama öldürülüp seans taslaktan
/// sürdürülünce de eski kart sahiplenilir, ikincisi açılmaz.
@available(iOS 16.2, *)
@MainActor
enum WorkoutLiveActivityController {
  private static var tail: Task<Void, Never>?

  private static func serial(_ op: @escaping @MainActor () async -> Void) {
    let previous = tail
    tail = Task { @MainActor in
      await previous?.value
      await op()
    }
  }

  private static func ms(_ v: Any?) -> Double? {
    (v as? Double) ?? (v as? Int).map(Double.init) ?? (v as? NSNumber)?.doubleValue
  }

  static func state(_ a: [String: Any]) -> WorkoutActivityAttributes.ContentState {
    .init(
      exercise: a["exercise"] as? String ?? "",
      setLabel: a["setLabel"] as? String ?? "",
      target: a["target"] as? String ?? "",
      restStartedAt: ms(a["restStartedAtMs"]).map { Date(timeIntervalSince1970: $0 / 1000) },
      restEndsAt: ms(a["restEndsAtMs"]).map { Date(timeIntervalSince1970: $0 / 1000) },
      doneSets: a["doneSets"] as? Int ?? 0,
      totalSets: a["totalSets"] as? Int ?? 0,
      canComplete: a["canComplete"] as? Bool ?? false)
  }

  static func attributes(_ a: [String: Any]) -> WorkoutActivityAttributes {
    let labels = a["labels"] as? [String: String] ?? [:]
    return WorkoutActivityAttributes(
      title: a["title"] as? String ?? "",
      startedAt: Date(timeIntervalSince1970: (ms(a["startedAtMs"]) ?? 0) / 1000),
      labels: .init(
        rest: labels["rest"] ?? "",
        restOver: labels["restOver"] ?? "",
        next: labels["next"] ?? "",
        completeSet: labels["completeSet"] ?? "",
        addRest: labels["addRest"] ?? "",
        skipRest: labels["skipRest"] ?? "",
        elapsed: labels["elapsed"] ?? ""))
  }

  /// Başlat ya da güncelle (tekil). `start`/`update` kanalı buraya gelir.
  static func upsert(args: [String: Any]) {
    let attrs = attributes(args)
    let st = state(args)
    // Dinlenme bitişi = bayatlama anı: sistem o an görünümü yeniden çizer
    // (`isStale`), uygulama uyurken de kart "Dinlenme bitti"ye geçer.
    let content = ActivityContent(state: st, staleDate: st.restEndsAt)
    serial {
      var kept = false
      for activity in Activity<WorkoutActivityAttributes>.activities {
        let same = !kept && activity.attributes.startedAt == attrs.startedAt
          && activity.activityState == .active
        if same {
          kept = true
          await activity.update(content)
        } else {
          await activity.end(nil, dismissalPolicy: .immediate)
        }
      }
      guard !kept, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
      _ = try? Activity.request(attributes: attrs, content: content, pushType: nil)
    }
  }

  /// Sıradaki işlemler bitene kadar bekler — kilit ekranı düğmesi dönmeden
  /// önce kartın güncellenmiş olması için (sistem ardından uygulamayı uyutur).
  static func drain() async {
    await tail?.value
  }

  static func endAll() {
    serial {
      for activity in Activity<WorkoutActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
  }
}
