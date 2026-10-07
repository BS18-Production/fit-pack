import ActivityKit
import Foundation

/// ActivityKit sarmalayıcısı — yalnız `AppDelegate` kanalından çağrılır.
/// Aynı anda tek antrenman etkinliği olur; yeni başlatma eskileri kapatır.
@available(iOS 16.2, *)
enum WorkoutLiveActivityController {
  static func state(_ a: [String: Any]) -> WorkoutActivityAttributes.ContentState {
    let restMs = a["restEndsAtMs"] as? Double ?? (a["restEndsAtMs"] as? Int).map(Double.init)
    return .init(
      exercise: a["exercise"] as? String ?? "",
      setLabel: a["setLabel"] as? String ?? "",
      target: a["target"] as? String ?? "",
      restEndsAt: restMs.map { Date(timeIntervalSince1970: $0 / 1000) },
      doneSets: a["doneSets"] as? Int ?? 0,
      totalSets: a["totalSets"] as? Int ?? 0)
  }

  static func start(args: [String: Any]) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let startedMs = args["startedAtMs"] as? Double ?? (args["startedAtMs"] as? Int).map(Double.init) ?? 0
    let attrs = WorkoutActivityAttributes(
      title: args["title"] as? String ?? "",
      startedAt: Date(timeIntervalSince1970: startedMs / 1000))
    let content = ActivityContent(state: state(args), staleDate: nil)
    Task {
      for activity in Activity<WorkoutActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      _ = try? Activity.request(attributes: attrs, content: content, pushType: nil)
    }
  }

  static func update(args: [String: Any]) {
    let content = ActivityContent(state: state(args), staleDate: nil)
    Task {
      for activity in Activity<WorkoutActivityAttributes>.activities {
        await activity.update(content)
      }
    }
  }

  static func endAll() {
    Task {
      for activity in Activity<WorkoutActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
  }
}
