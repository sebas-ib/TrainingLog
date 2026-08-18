//
//  DurationFormatting.swift
//  TrainingLog
//

import Foundation

/// Formats a duration in seconds as "M:SS" (or "MM:SS" past 9 minutes) —
/// the one display format every timer-adjacent view on the workout
/// screen uses, previously reimplemented separately in SetRowView,
/// TimerOverlayView, WorkoutDetailView, and DigitStuffingDurationField.
enum DurationFormatting {
    static func minutesSeconds(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
