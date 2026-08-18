//
//  Timer+LiveActivity.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//

import Foundation
import UIKit
import AudioToolbox


extension Timer {

    // MARK: - Rest Countdown

    /// Starts (or resumes) the timer and syncs the Live Activity to the
    /// remaining time. If the timer already crossed its target, resets
    /// first so a stale "0:00, done" state doesn't get resumed.
    func startRestCountdown() {
        if hasCrossedTarget {
            reset()
        }
        guard !isRunning else { return }

        // Only one timer is ever active — this pauses whatever set or
        // rest timer was previously running so it doesn't keep counting
        // invisibly once this one takes the app's single Live Activity
        // slot.
        WorkoutTimerActivityManager.shared.takeOver(self)

        onTargetCrossed = { [weak self] in
            guard let self else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            AudioServicesPlaySystemSound(1057)
            self.pause()
            WorkoutTimerActivityManager.shared.release(self)
            WorkoutTimerActivityManager.shared.complete()
        }

        start()
        WorkoutTimerActivityManager.shared.startCountdown(duration: remainingSeconds)
    }

    /// Pauses the timer and ends the Live Activity.
    func pauseRestCountdown() {
        pause()
        WorkoutTimerActivityManager.shared.release(self)
        WorkoutTimerActivityManager.shared.end()
    }

    /// Resets the timer and ends the Live Activity.
    func resetRestCountdown() {
        reset()
        WorkoutTimerActivityManager.shared.release(self)
        WorkoutTimerActivityManager.shared.end()
    }

    /// Adjusts the target and, if running, updates the Live Activity's
    /// end date to match — used by the ± step buttons in the overlay.
    func adjustRestTarget(by delta: Int) {
        adjustTarget(by: delta)
        guard isRunning else { return }
        WorkoutTimerActivityManager.shared.update(
            endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds))
        )
    }

    // MARK: - Set Stopwatch

    /// Starts (or resumes) the timer and mirrors it into a Live Activity,
    /// same as the rest countdown does — just counting up instead of
    /// down, since a set has no fixed end. `label` identifies which
    /// exercise/set is being timed, e.g. "Plank · Set 2".
    func startSetTimer(label: String) {
        guard !isRunning else { return }

        // Same hand-off as rest: starting this stopwatch pauses whatever
        // other set/rest timer was running, so at most one timer is ever
        // actually counting — and visible — at a time.
        WorkoutTimerActivityManager.shared.takeOver(self)

        // Unlike rest, crossing target doesn't pause or complete() —
        // a set just keeps counting past it, so the default
        // onTargetCrossed (haptic + sound only) is left as-is.
        start()
        WorkoutTimerActivityManager.shared.startStopwatch(
            elapsedSeconds: elapsedSeconds,
            targetSeconds: targetSeconds,
            label: label
        )
    }

    /// Pauses the timer and ends the Live Activity.
    func pauseSetTimer() {
        pause()
        WorkoutTimerActivityManager.shared.release(self)
        WorkoutTimerActivityManager.shared.end()
    }

    /// Resets the timer and ends the Live Activity.
    func resetSetTimer() {
        reset()
        WorkoutTimerActivityManager.shared.release(self)
        WorkoutTimerActivityManager.shared.end()
    }
}
