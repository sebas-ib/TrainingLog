//
//  Orderable.swift
//  TrainingLog
//

/// Conformed to by every model whose display order is tracked via an
/// explicit `order` property rather than trusted from SwiftData's
/// relationship-array order, which isn't guaranteed to survive a
/// fetch/save round-trip. `ExerciseSet` and `WorkoutExercise` both
/// needed the exact same "sort by order" operation, previously
/// copy-pasted as `.sorted { $0.order < $1.order }` at nine separate
/// call sites across the workout screen.
protocol Orderable {
    var order: Int { get }
}

extension Sequence where Element: Orderable {
    func sortedByOrder() -> [Element] {
        sorted { $0.order < $1.order }
    }
}
