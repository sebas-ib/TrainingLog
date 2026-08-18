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
            label: nil
        )
    }

    // MARK: - Start (Set Stopwatch)

    /// `elapsedSeconds` is however much the stopwatch had already
    /// counted, so resuming a paused set picks up the Live Activity from
    /// the right total instead of restarting it at zero.
    func startStopwatch(elapsedSeconds: Int, targetSeconds: Int, label: String) {
        let startedAt = Date().addingTimeInterval(-TimeInterval(elapsedSeconds))

        start(
            kind: .setTimer,
            startedAt: startedAt,
            endDate: startedAt.addingTimeInterval(Self.stopwatchCeiling),
            targetSeconds: targetSeconds,
            label: label
        )
    }

    private func start(
        kind: WorkoutTimerAttributes.Kind,
        startedAt: Date,
        endDate: Date,
        targetSeconds: Int,
        label: String?
    ) {
        guard ActivityAuthorizationInfo()
            .areActivitiesEnabled else {
            print("Live Activities are disabled.")
            return
        }

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

        let content = ActivityContent(
            state: state,
            // A stopwatch's endDate is an arbitrary ceiling, not a real
            // deadline, so there's nothing meaningful to go stale at.
            staleDate: kind == .restCountdown ? endDate : nil
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
    /// state the user can tap back into the app from — then lets it
    /// linger on the Lock Screen/Dynamic Island for a grace period before
    /// auto-dismissing, rather than vanishing instantly like end().
    /// Only meaningful for a rest countdown — a set stopwatch has no
    /// finish line, it just keeps counting until paused/reset.
    ///
    /// Deliberately does *not* clear `activity` afterward: the Live
    /// Activity is still alive at the OS level for the whole linger
    /// window, and start() needs the reference to dismiss it immediately
    /// if a new timer begins before that window elapses. Clearing it
    /// here would let a same-window restart race the still-lingering
    /// activity into ActivityKit's concurrent-activity limit.
    func complete(lingerFor seconds: TimeInterval = 60) {
        guard let activity else {
            return
        }

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
            await activity.end(
                content,
                dismissalPolicy: .after(Date().addingTimeInterval(seconds))
            )
        }

        print("Live Activity completed.")
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

        print("Live Activity ended.")
    }
}
