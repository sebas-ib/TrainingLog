//
//  WorkoutTimerActivityManager.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//
import ActivityKit
import Foundation

/// Drives the single Live Activity every timer in the app shares — the
/// between-set rest countdown and the per-set duration stopwatch. Only
/// one timer is ever meaningfully "the current one" (you're either
/// resting or actively timing a set, not both), so a new start() hands
/// off whatever's currently tracked exactly like resuming rest after a
/// target nudge always has.
@MainActor
final class WorkoutTimerActivityManager {

    static let shared = WorkoutTimerActivityManager()

    private init() {}

    private var activity:
        Activity<WorkoutTimerAttributes>?

    /// Whichever timer most recently became active — weakly held, since
    /// a set row's Timer only lives as long as its SetRowView and this
    /// bookkeeping shouldn't be what keeps it alive.
    private weak var activeTimer: Timer?

    /// Whether the tracked activity is sitting in `complete()`'s "Done"
    /// state, waiting to be cleared. Tracked separately from `activity`
    /// itself (which stays non-nil the whole time it's lingering) so
    /// `dismissIfCompleted()` can tell a finished-and-lingering activity
    /// apart from one that's still actively counting.
    private var isCompleted = false

    /// How far out `endDate` is set for a stopwatch, which has no real
    /// deadline — just needs a bound far enough that no realistic single
    /// set runs into it while still satisfying `Text(timerInterval:)`'s
    /// bounded-range API.
    private static let stopwatchCeiling: TimeInterval = 6 * 60 * 60

    // MARK: - Active Timer

    /// Marks `timer` as the app's one active timer, pausing whichever
    /// *other* timer was previously active first. There's only one Live
    /// Activity slot, so starting a second set's stopwatch while the
    /// first is still going — or starting a rest period mid-set, or
    /// vice versa — should read as switching to the new timer, not as
    /// quietly running a clock that's no longer visible anywhere.
    ///
    /// Deliberately pauses the *local* timer only, via the base
    /// `pause()`, rather than routing through `pauseRestCountdown()` /
    /// `pauseSetTimer()`: those also call `end()` on this same manager,
    /// which would race the very next line's `startCountdown` /
    /// `startStopwatch` — two independent, unawaited `Task`s both
    /// touching ActivityKit — instead of letting that call's own
    /// hand-off (which awaits the old activity's end() before
    /// requesting the new one) be the single path that ever does.
    func takeOver(_ timer: Timer) {
        if let activeTimer, activeTimer !== timer {
            activeTimer.pause()
        }
        activeTimer = timer
    }

    /// Clears `activeTimer` if `timer` is the one currently tracked —
    /// called whenever a timer is deliberately paused or reset, so a
    /// stale reference to an already-idle timer doesn't linger.
    func release(_ timer: Timer) {
        if activeTimer === timer {
            activeTimer = nil
        }
    }

    // MARK: - Start (Rest Countdown)

    func startCountdown(duration: Int) {
        guard duration > 0 else {
            print("Live Activity not started — duration was \(duration).")
            return
        }

        let startedAt = Date()

        start(
            kind: .restCountdown,
            startedAt: startedAt,
            endDate: startedAt.addingTimeInterval(TimeInterval(duration)),
            targetSeconds: duration,
            label: nil,
            // Prompts the system to refresh the widget's view around
            // the real completion moment — see the long staleDate note
            // below for why this matters even for a wall-clock-derived
            // "done" check.
            staleDate: startedAt.addingTimeInterval(TimeInterval(duration))
        )
    }

    // MARK: - Start (Set Stopwatch)

    /// `elapsedSeconds` is however much the stopwatch had already
    /// counted, so resuming a paused set picks up the Live Activity from
    /// the right total instead of restarting it at zero.
    func startStopwatch(elapsedSeconds: Int, targetSeconds: Int, label: String) {
        let startedAt = Date().addingTimeInterval(-TimeInterval(elapsedSeconds))

        // Unlike the stopwatch's arbitrary 6-hour endDate ceiling, this
        // is a real, meaningful moment — the instant the widget's
        // "past target, turn green" check should start being true — so
        // it's what staleDate points at, not the ceiling.
        let crossDate = targetSeconds > 0
            ? startedAt.addingTimeInterval(TimeInterval(targetSeconds))
            : nil

        start(
            kind: .setTimer,
            startedAt: startedAt,
            endDate: startedAt.addingTimeInterval(Self.stopwatchCeiling),
            targetSeconds: targetSeconds,
            label: label,
            staleDate: crossDate
        )
    }

    private func start(
        kind: WorkoutTimerAttributes.Kind,
        startedAt: Date,
        endDate: Date,
        targetSeconds: Int,
        label: String?,
        staleDate: Date?
    ) {
        guard ActivityAuthorizationInfo()
            .areActivitiesEnabled else {
            print("Live Activities are disabled.")
            return
        }

        // A fresh timer is, by definition, not sitting in a finished
        // "Done" state waiting to be dismissed.
        isCompleted = false

        let attributes = WorkoutTimerAttributes(
            kind: kind,
            startedAt: startedAt,
            targetSeconds: targetSeconds,
            label: label
        )

        let state =
            WorkoutTimerAttributes.ContentState(
                endDate: endDate
            )

        // `Text(timerInterval:)` ticks its own displayed digits natively
        // without re-running the widget's view code, so anything that
        // only reads true wall-clock time (isDone, hasCrossedTarget) —
        // as opposed to what's baked into the pushed ContentState —
        // won't actually update on screen until *something* re-renders
        // the view. `staleDate` is what prompts the system to do that
        // around a meaningful moment (rest's real end / a set's target
        // crossing) even while the app is backgrounded and can't push
        // an update itself.
        let content = ActivityContent(
            state: state,
            staleDate: staleDate
        )

        // Hand off whatever activity we're currently tracking — running,
        // or merely lingering post-complete() — and clear our reference
        // to it up front. The hand-off is awaited *inside* the Task below
        // before the new request goes out, so this can't race the new
        // request into ActivityKit's concurrent-activity limit the way
        // calling end() (a separate, unawaited fire-and-forget) followed
        // immediately by Activity.request() could.
        let previousActivity = activity
        activity = nil

        Task {
            if let previousActivity {
                let endedState =
                    WorkoutTimerAttributes.ContentState(
                        endDate: Date()
                    )

                let endedContent = ActivityContent(
                    state: endedState,
                    staleDate: nil
                )

                await previousActivity.end(
                    endedContent,
                    dismissalPolicy: .immediate
                )
            }

            do {
                activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )

                print("Live Activity started (\(kind)).")
            } catch {
                print(
                    "Failed to start Live Activity: \(error)"
                )
            }
        }
    }

    // MARK: - Refresh

    /// Nudges the running activity with its own unchanged content —
    /// purely to force the widget to re-render and recheck anything
    /// derived from wall-clock time, like a set stopwatch just crossing
    /// its target. `staleDate` and a `TimelineView` in the widget are
    /// both best-effort at prompting that on their own; an explicit
    /// `update()` is the one thing ActivityKit actually guarantees
    /// triggers a redraw — it's the same reason `complete()` reliably
    /// flips a finished rest over to "Done" rather than the wall-clock
    /// fallback quietly doing that work on its own.
    func refresh() {
        guard let activity else {
            return
        }

        Task {
            await activity.update(activity.content)
        }
    }

    // MARK: - Update

    /// Pushes a new end date to the running activity — e.g. when the
    /// user nudges the rest target while resting. No-ops if there's no
    /// active activity.
    func update(endDate: Date) {
        guard let activity else {
            return
        }

        let state =
            WorkoutTimerAttributes.ContentState(
                endDate: endDate
            )

        let content = ActivityContent(
            state: state,
            staleDate: endDate
        )

        Task {
            await activity.update(content)
        }
    }

    // MARK: - Complete

    /// Marks the activity as finished — the widget switches to a "Done"
    /// state the user can tap back into the app from.
    ///
    /// Deliberately calls `update(_:)`, not `end(_:dismissalPolicy:)`:
    /// ending the activity — even with `.default`, even with a long
    /// custom `.after(...)` date — starts the system's own removal
    /// clock for it, and in practice that made the Dynamic Island
    /// presence disappear right at the 0:00 mark instead of lingering.
    /// Pushing the finished state through an *update* keeps the activity
    /// genuinely running (never ended), which is the only way to
    /// guarantee nothing auto-removes it — it stays showing "Done" until
    /// something in this app explicitly ends it: `dismissIfCompleted()`
    /// once the user comes back, or a new timer's hand-off in `start()`.
    /// Only meaningful for a rest countdown — a set stopwatch has no
    /// finish line, it just keeps counting until paused/reset.
    func complete() {
        guard let activity else {
            return
        }

        isCompleted = true

        let state =
            WorkoutTimerAttributes.ContentState(
                endDate: Date(),
                isCompleted: true
            )

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        Task {
            await activity.update(content)
        }

        print("Live Activity completed.")
    }

    /// Clears a lingering "Done" activity now that the user has actually
    /// come back to the app and seen it — called when the app returns to
    /// the foreground. No-ops if the tracked activity is still actively
    /// counting rather than sitting in the completed state, so this
    /// can't cut off a rest/set timer just because the app was
    /// backgrounded and reopened mid-run.
    func dismissIfCompleted() {
        guard isCompleted else {
            return
        }

        end()
    }

    // MARK: - End

    func end() {
        guard let activity else {
            return
        }

        let state =
            WorkoutTimerAttributes.ContentState(
                endDate: Date()
            )

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        Task {
            await activity.end(
                content,
                dismissalPolicy: .immediate
            )
        }

        self.activity = nil
        isCompleted = false

        print("Live Activity ended.")
    }
}
