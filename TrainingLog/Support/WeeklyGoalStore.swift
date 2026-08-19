//
//  WeeklyGoalStore.swift
//  TrainingLog
//

import Foundation
import Combine

/// Per-muscle-group weekly set targets, adjustable by the user and
/// persisted across launches. Backed directly by `UserDefaults` rather
/// than a SwiftData model — a handful of small integers with no need
/// for querying, relationships, or migration machinery.
@MainActor
final class WeeklyGoalStore: ObservableObject {
    static let defaultWeeklySetGoal = 15

    @Published private var goalsByGroup: [String: Int]

    private static let defaultsKey = "weeklySetGoalsByMuscleGroup"

    init() {
        goalsByGroup = (UserDefaults.standard.dictionary(forKey: Self.defaultsKey) as? [String: Int]) ?? [:]
    }

    func goal(for group: MuscleGroup) -> Int {
        goalsByGroup[group.rawValue] ?? Self.defaultWeeklySetGoal
    }

    func setGoal(_ value: Int, for group: MuscleGroup) {
        goalsByGroup[group.rawValue] = value
        UserDefaults.standard.set(goalsByGroup, forKey: Self.defaultsKey)
    }
}
