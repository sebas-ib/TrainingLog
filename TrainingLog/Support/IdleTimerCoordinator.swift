//
//  IdleTimerCoordinator.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//
import UIKit

/// Multiple Timer instances (per-set stopwatches, the shared rest timer)
/// can run concurrently, but `isIdleTimerDisabled` is a single app-wide
/// flag. This reference-counts "who wants the screen awake" so one
/// timer pausing doesn't turn off idle-lock protection for another
/// timer that's still running.
@MainActor
enum IdleTimerCoordinator {
    private static var activeCount = 0

    static func acquire() {
        activeCount += 1
        UIApplication.shared.isIdleTimerDisabled = true
    }

    static func release() {
        activeCount = max(0, activeCount - 1)
        if activeCount == 0 {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
