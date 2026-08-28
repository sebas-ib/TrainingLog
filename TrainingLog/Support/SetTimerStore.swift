//
//  SetTimerStore.swift
//  TrainingLog
//

import Combine
import Foundation
import SwiftData

/// Owns the per-set stopwatches for one workout screen, keyed by set.
///
/// These used to live in `SetRowView` as `@State`, which tied a running
/// stopwatch's lifetime to its row being on screen: `List` recycles rows
/// once they scroll out of view, so SwiftUI would discard the row's
/// `@State` — and with it the `Timer` — while the user was still timing
/// a set. Scrolling down to glance at another exercise mid-plank was
/// enough to silently stop the clock, and because the row's
/// `onDisappear` called `suspend()` (which doesn't notify
/// `WorkoutTimerActivityManager`), the Live Activity kept counting from
/// a timer that no longer existed.
///
/// Holding them here instead — above the `List`, for as long as the
/// workout screen itself is up — means a running set timer survives
/// scrolling, and the row that scrolls back into view rebinds to the
/// same still-running `Timer` rather than a fresh stopped one.
@MainActor
final class SetTimerStore: ObservableObject {

    // Deliberately not `@Published`: the stored `Timer`s are `@Observable`
    // and drive their own view updates, and `timer(for:)` is called from
    // inside `body`, where publishing a change would re-enter the update
    // it was called from.
    private var timers: [PersistentIdentifier: Timer] = [:]

    /// The stopwatch for `set`, created on first request and reused
    /// afterward. `defaultTargetSeconds` seeds the target only for a
    /// newly-created timer — an existing one keeps whatever target the
    /// user has since dialed in via the +/- controls.
    func timer(for set: ExerciseSet, defaultTargetSeconds: Int) -> Timer {
        if let existing = timers[set.persistentModelID] {
            return existing
        }

        let timer = Timer(
            initialSeconds: set.durationSeconds,
            targetSeconds: defaultTargetSeconds
        )
        timers[set.persistentModelID] = timer
        return timer
    }

    /// Drops a deleted set's stopwatch so the dictionary doesn't keep
    /// accumulating entries for sets that no longer exist.
    func discard(_ set: ExerciseSet) {
        timers.removeValue(forKey: set.persistentModelID)?.suspend()
    }

    /// Stops every stopwatch — called when the workout screen goes away,
    /// which is now the point at which a running set timer should
    /// actually stop. This is also what releases
    /// `IdleTimerCoordinator`'s "keep the screen awake" count; letting
    /// the timers simply deallocate would leak it, since `Timer.deinit`
    /// only cancels its tick loop and can't safely touch `UIApplication`.
    func suspendAll() {
        for timer in timers.values {
            timer.suspend()
        }
    }
}
