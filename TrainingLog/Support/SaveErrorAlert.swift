//
//  SaveErrorAlert.swift
//  TrainingLog
//

import SwiftUI
import SwiftData

/// The one "we couldn't write your changes to disk" alert, shared by
/// every screen that saves. Previously only HomeView and WorkoutListView
/// surfaced a failed save at all — each with its own hand-rolled copy of
/// the same `Error?`-to-`Bool` binding plus alert — while the workout
/// screen, the exercise form, and the exercise picker used bare
/// `try?`/`print`, so a failed write during a workout lost logged sets
/// with no feedback at all.
extension View {
    func saveErrorAlert(_ error: Binding<Error?>) -> some View {
        alert(
            "Couldn't Save Changes",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented { error.wrappedValue = nil }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
        } message: {
            Text(
                error.wrappedValue?.localizedDescription
                ?? "An unknown error occurred while saving your workout."
            )
        }
    }
}

extension ModelContext {
    /// Saves, routing any failure into `destination` so the caller's
    /// `saveErrorAlert` can present it. The counterpart to the bare
    /// `try? save()` this replaces — same call-site ergonomics, but a
    /// failure is no longer silent.
    ///
    /// Deliberately does *not* roll back on failure: the unsaved changes
    /// are the user's just-logged sets, so they're left in the context
    /// where the next save can still flush them, rather than discarded
    /// to make the error easier to reason about.
    @MainActor
    func save(reportingTo destination: Binding<Error?>) {
        do {
            try save()
        } catch {
            destination.wrappedValue = error
        }
    }
}
