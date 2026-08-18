//
//  TrainingLogWidgetLiveActivity.swift
//  TrainingLogWidget
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TrainingLogWidgetLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutTimerAttributes.self) { context in

            // MARK: - Lock Screen

            LockScreenTimerView(context: context)

        } dynamicIsland: { context in

            // MARK: - Dynamic Island

            let isSetTimer = context.attributes.kind == .setTimer
            let isDone = Self.isDone(context)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: Self.leadingIcon(context))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isDone ? .green : Theme.accent)

                        Text(Self.title(context))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isDone ? .green : .primary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if isDone {
                        HStack(spacing: 4) {
                            Text("Tap to return")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    } else {
                        Text(timerInterval: Self.textInterval(context), countsDown: !isSetTimer)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.accent)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !isDone, let ringInterval = Self.ringInterval(context) {
                        VStack(spacing: 5) {
                            ProgressView(
                                timerInterval: ringInterval,
                                countsDown: false
                            )
                            .tint(Theme.accent)

                            Text("Target \(Self.formatted(context.attributes.targetSeconds))")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }
                }
            } compactLeading: {
                Image(systemName: Self.leadingIcon(context))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isDone ? .green : Theme.accent)
            } compactTrailing: {
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Text(timerInterval: Self.textInterval(context), countsDown: !isSetTimer)
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                        .frame(width: 44, alignment: .trailing)
                }
            } minimal: {
                Image(systemName: Self.leadingIcon(context))
                    .foregroundStyle(isDone ? .green : Theme.accent)
            }
            .keylineTint(isDone ? .green : Theme.accent)
        }
    }

    // MARK: - Shared Helpers

    /// Whether the activity should be presented as finished. Only a rest
    /// countdown ever reaches "done" — a set stopwatch has no finish
    /// line, it just keeps counting until the app pauses or resets it.
    ///
    /// This used to be `context.state.isCompleted || context.isStale`.
    /// `isCompleted` is only ever set by the app explicitly calling
    /// `WorkoutTimerActivityManager.complete()` — which requires the
    /// app's own `Timer` polling loop to still be executing to notice
    /// the target was crossed. But locking the phone (or switching away)
    /// mid-rest — the single most common way to use a rest timer —
    /// suspends that loop, so the app can silently miss the crossing
    /// entirely until it's reopened. `context.isStale` was meant to
    /// cover exactly this via the activity's `staleDate`, but its
    /// refresh timing is system-scheduled and not always prompt, which
    /// is why "Done" sometimes never showed even though the countdown
    /// had reached zero. Adding a direct comparison against `endDate`
    /// makes the "done" state derivable from wall-clock time alone,
    /// independent of whether the app or the system got around to
    /// flagging it.
    static func isDone(_ context: ActivityViewContext<WorkoutTimerAttributes>) -> Bool {
        guard context.attributes.kind == .restCountdown else { return false }
        return context.state.isCompleted || context.isStale || context.state.endDate <= Date()
    }

    static func leadingIcon(_ context: ActivityViewContext<WorkoutTimerAttributes>) -> String {
        if isDone(context) { return "checkmark.circle.fill" }
        return context.attributes.kind == .setTimer ? "stopwatch" : "timer"
    }

    static func title(_ context: ActivityViewContext<WorkoutTimerAttributes>) -> String {
        if isDone(context) { return "Done" }
        switch context.attributes.kind {
        case .restCountdown: return "Resting"
        case .setTimer: return context.attributes.label ?? "Timing"
        }
    }

    /// The interval fed to `Text(timerInterval:)` — counts down to
    /// `endDate` for a rest countdown, or counts up from the stopwatch's
    /// true start for a set timer (its `endDate` is just a distant
    /// ceiling to satisfy the API, not a real deadline).
    static func textInterval(_ context: ActivityViewContext<WorkoutTimerAttributes>) -> ClosedRange<Date> {
        switch context.attributes.kind {
        case .restCountdown:
            return Date.now...context.state.endDate
        case .setTimer:
            return context.attributes.startedAt...context.state.endDate
        }
    }

    /// The interval behind the progress ring, when there's a target to
    /// show progress toward — nil (no ring) otherwise.
    static func ringInterval(_ context: ActivityViewContext<WorkoutTimerAttributes>) -> ClosedRange<Date>? {
        guard context.attributes.targetSeconds > 0 else { return nil }

        switch context.attributes.kind {
        case .restCountdown:
            return context.attributes.startedAt...context.state.endDate
        case .setTimer:
            let crossDate = context.attributes.startedAt.addingTimeInterval(
                TimeInterval(context.attributes.targetSeconds)
            )
            return context.attributes.startedAt...crossDate
        }
    }

    static func formatted(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Lock Screen

private struct LockScreenTimerView: View {
    let context: ActivityViewContext<WorkoutTimerAttributes>

    private var isDone: Bool {
        TrainingLogWidgetLiveActivity.isDone(context)
    }

    private var isSetTimer: Bool {
        context.attributes.kind == .setTimer
    }

    private var targetLabel: String? {
        guard context.attributes.targetSeconds > 0 else { return nil }
        return "Target \(TrainingLogWidgetLiveActivity.formatted(context.attributes.targetSeconds))"
    }

    private var subtitle: String {
        if isSetTimer {
            return context.attributes.label ?? "Timing"
        }
        return targetLabel ?? "Rest"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isDone ? Color.green.opacity(0.15) : Theme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: TrainingLogWidgetLiveActivity.leadingIcon(context))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isDone ? .green : Theme.accent)
            }

            if isDone {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest complete")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Tap to return to your workout")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(
                        timerInterval: TrainingLogWidgetLiveActivity.textInterval(context),
                        countsDown: !isSetTimer
                    )
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                    if isSetTimer, let targetLabel {
                        Text(targetLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let ringInterval = TrainingLogWidgetLiveActivity.ringInterval(context) {
                    ProgressView(timerInterval: ringInterval, countsDown: false)
                        .progressViewStyle(.circular)
                        .tint(Theme.accent)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(.systemBackground))
        .activitySystemActionForegroundColor(Theme.accent)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isDone
                ? "Rest complete. Tap to return to your workout."
                : (isSetTimer ? "\(subtitle) timer running" : "Resting, \(subtitle.lowercased())")
        )
    }
}
