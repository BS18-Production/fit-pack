import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Kilit ekranı + Dynamic Island görünümü (docs/32, docs/45).
///
/// İki durum görsel olarak ayrılır:
/// - **Set:** sıradaki hareket + set hedefi, tek büyük "Seti tamamla".
/// - **Dinlenme:** büyük neon geri sayım + akan çubuk, "+15 sn" / "Atla",
///   altında sıradaki set. Süre dolunca (`isStale`) "Dinlenme bitti" ve
///   yeniden "Seti tamamla".
/// Toplam antrenman süresi her zaman üst satırda, ayrı etiketle — dinlenme
/// sayacıyla karışmaz. Tahmini bitiş süresi uydurulmaz.
/// Sayaçlar sistem tarafından çizilir (`timerInterval`) — uygulama uyurken
/// de akar. Düğmeler iOS 17+; altında yalnız görüntü (dokununca uygulama).
///
/// **Yükseklik bütçesi:** kilit ekranı kartı en çok ~160 pt; fazlası sistem
/// tarafından KESİLİR (iPhone'da düğmeler alttan kesildi, 2026-10-11). Kart
/// ~145 pt'ye göre ölçülü: kenar 12, sayaç 36 pt, düğme 32 pt.
@available(iOS 16.2, *)
struct WorkoutLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
      LockScreenView(context: context)
        .activityBackgroundTint(Palette.background)
        .activitySystemActionForegroundColor(Palette.lime)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text(context.state.setLabel)
          } icon: {
            Image(systemName: "dumbbell.fill")
          }
          .font(.caption.weight(.semibold))
          .foregroundStyle(Palette.lime)
          .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          RestOrElapsed(context: context)
            .font(.title3.weight(.bold))
            .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 8) {
            ExerciseLine(context: context, compact: true)
            ActionRow(context: context)
          }
          .padding(.horizontal, 4)
        }
      } compactLeading: {
        Image(systemName: isResting(context) ? "timer" : "dumbbell.fill")
          .foregroundStyle(Palette.lime)
      } compactTrailing: {
        RestOrElapsed(context: context)
          .font(.caption2.weight(.semibold)).frame(maxWidth: 52)
      } minimal: {
        Image(systemName: isResting(context) ? "timer" : "dumbbell.fill")
          .foregroundStyle(Palette.lime)
      }
    }
  }
}

// MARK: - Ortak

@available(iOS 16.2, *)
private enum Palette {
  /// FitPack neon lime — uygulamanın vurgu rengi.
  static let lime = Color(red: 0.80, green: 1.0, blue: 0.0)
  static let background = Color(red: 0.05, green: 0.06, blue: 0.05).opacity(0.92)
  static let secondary = Color.white.opacity(0.62)
  static let track = Color.white.opacity(0.14)
}

/// Dinlenme sürüyor mu: bitiş anı var ve henüz geçmedi (`isStale` = sistem
/// bitiş anında görünümü yeniden çizdi).
@available(iOS 16.2, *)
private func isResting(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> Bool {
  guard let end = context.state.restEndsAt else { return false }
  return !context.isStale && end > Date()
}

@available(iOS 16.2, *)
private func restJustEnded(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> Bool {
  context.state.restEndsAt != nil && !isResting(context)
}

@available(iOS 16.2, *)
private struct RestOrElapsed: View {
  let context: ActivityViewContext<WorkoutActivityAttributes>

  var body: some View {
    if isResting(context), let end = context.state.restEndsAt {
      Text(timerInterval: Date()...end, countsDown: true)
        .monospacedDigit().foregroundStyle(Palette.lime)
        .multilineTextAlignment(.trailing)
    } else {
      Text(context.attributes.startedAt, style: .timer)
        .monospacedDigit().foregroundStyle(.white)
        .multilineTextAlignment(.trailing)
    }
  }
}

@available(iOS 16.2, *)
private struct ExerciseLine: View {
  let context: ActivityViewContext<WorkoutActivityAttributes>
  var compact = false

  var body: some View {
    let s = context.state
    VStack(alignment: .leading, spacing: 2) {
      Text(s.exercise)
        .font(compact ? .subheadline.weight(.semibold) : .headline)
        .lineLimit(1)
        .foregroundStyle(.white)
      Text(s.target.isEmpty ? s.setLabel : "\(s.setLabel) · \(s.target)")
        .font(.subheadline)
        .monospacedDigit()
        .lineLimit(1)
        .foregroundStyle(Palette.secondary)
    }
  }
}

/// Duruma göre düğmeler. iOS 17 altında hiç çizilmez.
@available(iOS 16.2, *)
private struct ActionRow: View {
  let context: ActivityViewContext<WorkoutActivityAttributes>

  var body: some View {
    if #available(iOS 17.0, *) {
      let l = context.attributes.labels
      if isResting(context) {
        HStack(spacing: 8) {
          Button(intent: AddRestIntent()) {
            Text(l.addRest).frame(maxWidth: .infinity)
          }
          .buttonStyle(PillStyle(prominent: false))
          Button(intent: SkipRestIntent()) {
            Text(l.skipRest).frame(maxWidth: .infinity)
          }
          .buttonStyle(PillStyle(prominent: true))
        }
      } else if context.state.canComplete {
        Button(intent: CompleteSetIntent()) {
          Label(l.completeSet, systemImage: "checkmark")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PillStyle(prominent: true))
      }
    }
  }
}

@available(iOS 16.2, *)
private struct PillStyle: ButtonStyle {
  let prominent: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.subheadline.weight(.bold))
      .padding(.vertical, 7)
      .foregroundStyle(prominent ? Color.black : Color.white)
      .background(
        Capsule().fill(prominent ? Palette.lime : Palette.track))
      .opacity(configuration.isPressed ? 0.7 : 1)
  }
}

// MARK: - Kilit ekranı

@available(iOS 16.2, *)
private struct LockScreenView: View {
  let context: ActivityViewContext<WorkoutActivityAttributes>

  var body: some View {
    let s = context.state
    let l = context.attributes.labels
    VStack(alignment: .leading, spacing: 6) {
      // Üst satır: seans adı + toplam süre (etiketli — dinlenmeyle karışmaz).
      HStack(spacing: 6) {
        Image(systemName: "dumbbell.fill")
          .font(.caption.weight(.bold))
          .foregroundStyle(Palette.lime)
        Text(context.attributes.title)
          .font(.caption.weight(.bold))
          .textCase(.uppercase)
          .lineLimit(1)
          .foregroundStyle(.white)
        Spacer(minLength: 8)
        if s.totalSets > 0 {
          Text("\(s.doneSets)/\(s.totalSets)")
            .font(.caption.weight(.semibold)).monospacedDigit()
            .foregroundStyle(Palette.secondary)
          Text("·").font(.caption).foregroundStyle(Palette.secondary)
        }
        if !l.elapsed.isEmpty {
          Text(l.elapsed).font(.caption).foregroundStyle(Palette.secondary)
        }
        Text(context.attributes.startedAt, style: .timer)
          .font(.caption.weight(.semibold)).monospacedDigit()
          .foregroundStyle(.white)
          .frame(maxWidth: 64, alignment: .trailing)
      }

      if isResting(context), let end = s.restEndsAt {
        RestBlock(context: context, end: end)
      } else {
        VStack(alignment: .leading, spacing: 6) {
          if restJustEnded(context) {
            Text(l.restOverOrNext)
              .font(.caption.weight(.bold))
              .textCase(.uppercase)
              .foregroundStyle(Palette.lime)
          }
          ExerciseLine(context: context)
          if s.totalSets > 0 {
            ProgressView(value: Double(s.doneSets), total: Double(s.totalSets))
              .tint(Palette.lime)
          }
          ActionRow(context: context)
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
  }
}

@available(iOS 16.2, *)
private struct RestBlock: View {
  let context: ActivityViewContext<WorkoutActivityAttributes>
  let end: Date

  var body: some View {
    let s = context.state
    let l = context.attributes.labels
    let start = min(s.restStartedAt ?? Date(), end)
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .lastTextBaseline) {
        VStack(alignment: .leading, spacing: 0) {
          Text(l.rest)
            .font(.caption.weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(Palette.lime)
          Text(timerInterval: Date()...end, countsDown: true)
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Palette.lime)
        }
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 2) {
          Text(l.next)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(Palette.secondary)
          Text(s.exercise)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(.white)
          Text(s.target.isEmpty ? s.setLabel : "\(s.setLabel) · \(s.target)")
            .font(.caption)
            .monospacedDigit()
            .lineLimit(1)
            .foregroundStyle(Palette.secondary)
        }
      }
      ProgressView(timerInterval: start...end, countsDown: true) {
        EmptyView()
      } currentValueLabel: {
        EmptyView()
      }
      .tint(Palette.lime)
      ActionRow(context: context)
    }
  }
}

@available(iOS 16.2, *)
private extension WorkoutActivityAttributes.Labels {
  /// Dinlenme bittiğinde kilit ekranında görünen kısa durum.
  var restOverOrNext: String { restOver.isEmpty ? next : restOver }
}
