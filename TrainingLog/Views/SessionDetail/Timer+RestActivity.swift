//
//  Timer+RestActivity.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//

import Foundation
import UIKit
import AudioToolbox


extension Timer {

    /// Starts (or resumes) the timer and syncs the Live Activity to the
    /// remaining time. If the timer already crossed its target, resets
    /// first so a stale "0:00, done" state doesn't get resumed.
    func startRestCountdown() {
        if hasCrossedTarget {
            reset()
        }
        guard !isRunning else { return }

        onTargetCrossed = { [weak self] in
            guard let self else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            AudioServicesPlaySystemSound(1057)
            self.pause()
            RestActivityManager.shared.complete()
        }

        start()
        RestActivityManager.shared.start(duration: remainingSeconds)
    }

    /// Pauses the timer and ends the Live Activity.
    func pauseRestCountdown() {
        pause()
        RestActivityManager.shared.end()
    }

    /// Resets the timer and ends the Live Activity.
    func resetRestCountdown() {
        reset()
        RestActivityManager.shared.end()
    }

    /// Adjusts the target and, if running, updates the Live Activity's
    /// end date to match — used by the ± step buttons in the overlay.
    func adjustRestTarget(by delta: Int) {
        adjustTarget(by: delta)
        guard isRunning else { return }
        RestActivityManager.shared.update(
            endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds))
        )
    }
}
