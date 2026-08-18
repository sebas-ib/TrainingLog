//
//  WorkoutTimerAttributes.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//
import ActivityKit
import Foundation

/// Live Activity payload shared by every timer in the app — the
/// between-set rest countdown and the per-set duration stopwatch both
/// render through the same widget, distinguished by `kind`. `startedAt`
/// and `endDate` carry different meanings depending on it:
///
/// - `.restCountdown`: `startedAt` is when this activity began, `endDate`
///   is the real moment the rest period hits zero. The widget shows
///   `Date.now...endDate` counting down.
/// - `.setTimer`: `startedAt` is back-dated by however much had already
///   elapsed when the stopwatch (re)started, so it doubles as the "zero
///   point" a resumed stopwatch counts up from; `endDate` is just a
///   distant ceiling (hours out) to satisfy `Text(timerInterval:)`'s API,
///   not a real deadline — a set has no fixed end.
struct WorkoutTimerAttributes: ActivityAttributes {

    enum Kind: String, Codable, Hashable {
        case restCountdown
        case setTimer
    }

    struct ContentState: Codable, Hashable {
        let endDate: Date
        var isCompleted: Bool = false
    }

    let kind: Kind
    let startedAt: Date
    let targetSeconds: Int
    /// e.g. "Bench Press · Set 2" — shown in the widget for a set timer.
    /// Unused (nil) for a rest activity.
    let label: String?
}
