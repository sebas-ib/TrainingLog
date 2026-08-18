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
        ActivityConfiguration(for: RestActivityAttributes.self) { context in

            // MARK: - Lock Screen

            LockScreenRestView(context: context)

        } dynamicIsland: { context in

            // MARK: - Dynamic Island

            let isDone = Self.isDone(context)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "timer")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isDone ? .green : Theme.accent)

                        Text(isDone ? "Done" : "Resting")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isDone ? .green : .primary)
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
                        Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.accent)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !isDone {
                        VStack(spacing: 5) {
                            ProgressView(
                                timerInterval: context.attributes.startedAt...context.state.endDate,
                                countsDown: false
                            )
                            .tint(Theme.accent)

                            Text("Target \(Self.formatted(Self.currentTargetSeconds(context)))")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }
                }
            } compactLeading: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "timer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isDone ? .green : Theme.accent)
            } compactTrailing: {
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                        .frame(width: 44, alignment: .trailing)
                }
            } minimal: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "timer")
                    .foregroundStyle(isDone ? .green : Theme.accent)
            }
            .keylineTint(isDone ? .green : Theme.accent)
        }
    }

    // MARK: - Shared Helpers

    /// Whether the rest period should be presented as finished.
    ///
    /// This used to be `context.state.isCompleted || context.isStale`.
    /// `isCompleted` is only ever set by the app explicitly calling
    /// `RestActivityManager.complete()` — which requires the app's own
    /// `Timer` polling loop to still be executing to notice the target
    /// was crossed. But locking the phone (or switching away) mid-rest —
    /// the single most common way to use a rest timer — suspends that
    /// loop, so the app can silently miss the crossing entirely until
    /// it's reopened. `context.isStale` was meant to cover exactly this
    /// via the activity's `staleDate`, but its refresh timing is
    /// system-scheduled and not always prompt, which is why "Done"
    /// sometimes never showed even though the countdown had reached
    /// zero. Adding a direct comparison against `endDate` makes the
    /// "done" state derivable from wall-clock time alone, independent of
    /// whether the app or the system got around to flagging it.
    static func isDone(_ context: ActivityViewContext<RestActivityAttributes>) -> Bool {
        context.state.isCompleted || context.isStale || context.state.endDate <= Date()
    }

    /// The rest target currently in effect, in seconds. Derived from
    /// `endDate - startedAt` rather than `attributes.targetSeconds`,
    /// since `targetSeconds` is fixed at activity creation and won't
    /// reflect the user nudging the target up/down mid-rest (that only
    /// updates `state.endDate`).
    static func currentTargetSeconds(_ context: ActivityViewContext<RestActivityAttributes>) -> Int {
        max(0, Int(context.state.endDate.timeIntervalSince(context.attributes.startedAt)))
    }

    static func formatted(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Lock Screen

private struct LockScreenRestView: View {
    let context: ActivityViewContext<RestActivityAttributes>

    private var isDone: Bool {
        TrainingLogWidgetLiveActivity.isDone(context)
    }

    private var targetLabel: String {
        "Target \(TrainingLogWidgetLiveActivity.formatted(TrainingLogWidgetLiveActivity.currentTargetSeconds(context)))"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isDone ? Color.green.opacity(0.15) : Theme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: isDone ? "checkmark" : "timer")
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
                    Text(targetLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }

                Spacer()

                ProgressView(
                    timerInterval: context.attributes.startedAt...context.state.endDate,
                    countsDown: false
                )
                .progressViewStyle(.circular)
                .tint(Theme.accent)
                .frame(width: 34, height: 34)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(.systemBackground))
        .activitySystemActionForegroundColor(Theme.accent)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isDone
                ? "Rest complete. Tap to return to your workout."
                : "Resting, \(targetLabel.lowercased())"
        )
    }
}
