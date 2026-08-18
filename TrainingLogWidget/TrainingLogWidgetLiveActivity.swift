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
            let isHighlighted = Self.isHighlighted(context)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    // Kept small and secondary on purpose — like the
                    // system Stopwatch's Dynamic Island, the elapsed/
                    // remaining number is the one thing that should read
                    // as "the point" here, not a competing headline.
                    TimelineView(.periodic(from: context.attributes.startedAt, by: Self.crossCheckInterval)) { timeline in
                        let highlighted = Self.isHighlighted(context, at: timeline.date)

                        VStack(alignment: .leading, spacing: 3) {
                            Image(systemName: Self.leadingIcon(context))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(highlighted ? .green : Theme.accent)

                            Text(Self.title(context))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(isDone ? .green : .secondary)
                                .lineLimit(1)
                        }
                        .padding(.leading, 4)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if isDone {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Tap to return")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.trailing, 4)
                    } else {
                        // The hero element — big, bold, tabular digits
                        // dominating the expanded island the way the
                        // system Stopwatch/Timer activities do.
                        TimelineView(.periodic(from: context.attributes.startedAt, by: Self.crossCheckInterval)) { timeline in
                            Text(timerInterval: Self.textInterval(context), countsDown: !isSetTimer)
                                .font(.system(size: 40))
                                .monospacedDigit()
                                .foregroundStyle(Self.hasCrossedTarget(context, at: timeline.date) ? .green : Theme.accent)
                                .contentTransition(.numericText())
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                                .padding(.trailing, 4)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !isDone, let ringInterval = Self.ringInterval(context) {
                        HStack(spacing: 8) {
                            ProgressView(
                                timerInterval: ringInterval,
                                countsDown: false
                            )
                            .tint(Theme.accent)
                            .frame(maxWidth: 120)

                            Text("Target \(Self.formatted(context.attributes.targetSeconds))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                TimelineView(.periodic(from: context.attributes.startedAt, by: Self.crossCheckInterval)) { timeline in
                    Image(systemName: Self.leadingIcon(context))
                        .font(.system(size: 20))
                        .foregroundStyle(Self.isHighlighted(context, at: timeline.date) ? .green : Theme.accent)
                }
            } compactTrailing: {
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13))
                        .foregroundStyle(.green)
                } else {
                    // `Text(timerInterval:)` alone reports an oversized,
                    // unstable intrinsic width in this specific compact-
                    // pill slot — enough in practice to stretch the pill
                    // across the whole island. An identically-styled
                    // plain `Text(String)` sizes correctly, so it's used
                    // here purely as an invisible sizing reference: via
                    // `.overlay`, ITS size is what gets reported to the
                    // Island, while the real ticking digits render on
                    // top through the native, OS-driven
                    // `Text(timerInterval:)` — so the digits themselves
                    // still update every second for free. The
                    // `TimelineView` wrapping it isn't for that — it's
                    // only there so the *color* rechecks whether target's
                    // been crossed periodically, instead of only once.
                    TimelineView(.periodic(from: context.attributes.startedAt, by: Self.crossCheckInterval)) { timeline in
                        Text(Self.formattedTimer(context))
                            .font(.system(size: 15))
                            .monospacedDigit()
                            .hidden()
                            .overlay(
                                Text(
                                    timerInterval: Self.textInterval(context),
                                    countsDown: !isSetTimer
                                )
                                .font(.system(size: 15))
                                .monospacedDigit()
                                .foregroundStyle(Self.hasCrossedTarget(context, at: timeline.date) ? .green : Theme.accent)
                                .contentTransition(.numericText())
                            )
                            .lineLimit(1)
                    }
                }
            } minimal: {
                // The minimal presentation has just the one glyph, no
                // separate leading/trailing pair to split the "done"
                // signal across — so unlike `leadingIcon`, this keeps
                // the checkmark here for a finished rest.
                TimelineView(.periodic(from: context.attributes.startedAt, by: Self.crossCheckInterval)) { timeline in
                    Image(systemName: isDone ? "checkmark.circle.fill" : Self.leadingIcon(context))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Self.isHighlighted(context, at: timeline.date) ? .green : Theme.accent)
                }
            }
            // Not wrapped in a TimelineView like the regions above —
            // `keylineTint` takes a plain Color, not a view builder, so
            // there's no slot here to put one in. It'll pick up
            // "past target" green whenever the system re-renders this
            // closure for some other reason, same imprecision the old
            // rest-only isDone check used to have everywhere.
            .keylineTint(isHighlighted ? .green : Theme.accent)
        }
    }

    // MARK: - Shared Helpers

    /// How often the `TimelineView`s scattered through the Dynamic
    /// Island recheck whether a set's target has been crossed. Only
    /// needs to be frequent enough that the color change feels prompt —
    /// once it's true it stays true, so there's nothing to gain from
    /// checking faster than this.
    static let crossCheckInterval: TimeInterval = 5

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

    /// For a set stopwatch only — true once elapsed time has passed its
    /// target. Unlike a rest countdown reaching zero, this doesn't stop
    /// or end anything; it's purely a "past target" color cue, derived
    /// the same wall-clock way `ringInterval`'s cross date is.
    /// `at` defaults to `Date()` for call sites that only need a one-off
    /// read, but every Dynamic Island call site below passes a
    /// `TimelineView`'s tick date explicitly instead: `Text(timerInterval:)`
    /// ticks its own digits without ever re-running the surrounding
    /// SwiftUI body, and a set stopwatch's `staleDate` (unlike rest's)
    /// isn't tied to anything the system's own render pipeline is
    /// already tracking, so relying on some future system-triggered
    /// refresh to notice `Date() >= crossDate` turned out to not
    /// reliably happen at all — the color would just never update. A
    /// periodic `TimelineView` forces that recheck itself instead of
    /// waiting on one.
    static func hasCrossedTarget(_ context: ActivityViewContext<WorkoutTimerAttributes>, at date: Date = Date()) -> Bool {
        guard context.attributes.kind == .setTimer, context.attributes.targetSeconds > 0 else {
            return false
        }

        let crossDate = context.attributes.startedAt.addingTimeInterval(
            TimeInterval(context.attributes.targetSeconds)
        )

        return date >= crossDate
    }

    /// Whether this activity should render in its "green" state —
    /// either a rest that's finished, or a set that's run past target.
    static func isHighlighted(_ context: ActivityViewContext<WorkoutTimerAttributes>, at date: Date = Date()) -> Bool {
        isDone(context) || hasCrossedTarget(context, at: date)
    }

    /// The leading icon — distinct per kind so a glance tells rest and
    /// set timing apart, not just the color does. A finished rest hands
    /// back to the workout with a weightlifting icon here; the checkmark
    /// that used to live here instead lives in the trailing slot (see
    /// `compactTrailing`), so the two don't say the same thing twice. A
    /// set stopwatch keeps its timer icon even past target — only the
    /// color changes there, via `isHighlighted`.
    static func leadingIcon(_ context: ActivityViewContext<WorkoutTimerAttributes>) -> String {
        if isDone(context) {
            return "figure.strengthtraining.traditional"
        }
        switch context.attributes.kind {
        case .restCountdown:
            return "figure.cooldown"
        case .setTimer:
            return "timer"
        }
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

    /// Matches `Text(timerInterval:)`'s own formatting switch — "M:SS"
    /// under an hour, "H:MM:SS" at or past it — so the sizing reference
    /// in `compactTrailing` widens at exactly the same threshold the
    /// real ticking text does, instead of clipping it once an hour of
    /// stopwatch time has passed.
    static func formatted(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// A one-off snapshot of the current remaining/elapsed time, as a
    /// plain string — used only as an invisible sizing reference (see
    /// `compactTrailing` above), never as the actual displayed digits.
    /// It doesn't need to re-run every second itself: it only has to be
    /// roughly right *when the widget happens to re-render*, so the
    /// reference stays close to the real digit count (e.g. widening once
    /// the display crosses from "9:59" into "10:00").
    static func formattedTimer(_ context: ActivityViewContext<WorkoutTimerAttributes>) -> String {
        let seconds: Int
        switch context.attributes.kind {
        case .restCountdown:
            seconds = max(0, Int(context.state.endDate.timeIntervalSinceNow.rounded(.up)))
        case .setTimer:
            seconds = max(0, Int(Date().timeIntervalSince(context.attributes.startedAt)))
        }
        return formatted(seconds)
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
        // Wrapped so `hasCrossedTarget`/`isHighlighted` — both plain
        // wall-clock comparisons — actually get rechecked periodically,
        // instead of only once whenever the system happens to re-render
        // this view for some unrelated reason. See the long comment on
        // `hasCrossedTarget` in the main widget type for why that's
        // necessary here specifically.
        TimelineView(.periodic(from: context.attributes.startedAt, by: TrainingLogWidgetLiveActivity.crossCheckInterval)) { timeline in
            let hasCrossedTarget = TrainingLogWidgetLiveActivity.hasCrossedTarget(context, at: timeline.date)
            let isHighlighted = TrainingLogWidgetLiveActivity.isHighlighted(context, at: timeline.date)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isHighlighted ? Color.green.opacity(0.15) : Theme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: TrainingLogWidgetLiveActivity.leadingIcon(context))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isHighlighted ? .green : Theme.accent)
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
                        .foregroundStyle(hasCrossedTarget ? .green : .primary)
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
}
