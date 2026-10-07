import ActivityKit
import SwiftUI
import WidgetKit

/// Kilit ekranı + Dynamic Island görünümü (docs/32). Sayaçlar sistem
/// tarafından çizilir (`Text(timerInterval:)`) — uygulama uykudayken de akar.
@available(iOS 16.2, *)
struct WorkoutLiveActivityWidget: Widget {
  private let lime = Color(red: 0.80, green: 1.0, blue: 0.0)

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
      LockScreenView(context: context, lime: lime)
        .activityBackgroundTint(Color.black.opacity(0.85))
        .activitySystemActionForegroundColor(lime)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text(context.state.setLabel).font(.caption).foregroundColor(lime)
        }
        DynamicIslandExpandedRegion(.trailing) {
          RestOrElapsed(context: context, lime: lime).font(.caption)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.state.exercise).font(.headline).lineLimit(1)
            if !context.state.target.isEmpty {
              Text(context.state.target).font(.subheadline)
                .foregroundColor(.secondary)
            }
          }
        }
      } compactLeading: {
        Image(systemName: "dumbbell.fill").foregroundColor(lime)
      } compactTrailing: {
        RestOrElapsed(context: context, lime: lime)
          .font(.caption2).frame(maxWidth: 52)
      } minimal: {
        Image(systemName: "dumbbell.fill").foregroundColor(lime)
      }
    }
  }
}

@available(iOS 16.2, *)
private struct RestOrElapsed: View {
  let context: ActivityViewContext<WorkoutActivityAttributes>
  let lime: Color

  var body: some View {
    if let end = context.state.restEndsAt, end > Date() {
      Text(timerInterval: Date()...end, countsDown: true)
        .monospacedDigit().foregroundColor(lime)
    } else {
      Text(context.attributes.startedAt, style: .timer)
        .monospacedDigit()
    }
  }
}

@available(iOS 16.2, *)
private struct LockScreenView: View {
  let context: ActivityViewContext<WorkoutActivityAttributes>
  let lime: Color

  var body: some View {
    let s = context.state
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "dumbbell.fill").foregroundColor(lime)
        Text(context.attributes.title).font(.subheadline).bold()
        Spacer()
        Text(context.attributes.startedAt, style: .timer)
          .font(.subheadline).monospacedDigit().foregroundColor(.secondary)
      }
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          Text(s.exercise).font(.headline).lineLimit(1)
          Text(s.target.isEmpty ? s.setLabel : "\(s.setLabel) · \(s.target)")
            .font(.subheadline).foregroundColor(.secondary)
        }
        Spacer()
        if let end = s.restEndsAt, end > Date() {
          Text(timerInterval: Date()...end, countsDown: true)
            .font(.title2).bold().monospacedDigit().foregroundColor(lime)
            .multilineTextAlignment(.trailing).frame(width: 80)
        }
      }
      if s.totalSets > 0 {
        ProgressView(value: Double(s.doneSets), total: Double(s.totalSets))
          .tint(lime)
      }
    }
    .padding(16)
    .foregroundColor(.white)
  }
}
