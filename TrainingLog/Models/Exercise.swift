//
//  Exercise.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation
import SwiftData

@Model
class Exercise {
    var name: String
    var isCustom: Bool
    var muscleGroupRawValue: String
    var secondaryMuscleGroupRawValue: String?
    var loggingTypeRawValue: String
    // Defaulted so SwiftData's lightweight migration can add these to
    // existing rows as empty arrays — an exercise created before
    // muscle-target tracking existed just has no specific targets yet,
    // rather than needing a real migration to backfill something.
    var primaryMuscleTargetRawValues: [String] = []
    var secondaryMuscleTargetRawValues: [String] = []

    /// The starter-library name this exercise was seeded from, if it was.
    /// Seeding used to match purely on the *current* name, so renaming a
    /// stock exercise ("Bench Press" → "BP") made it invisible to the
    /// matcher and a duplicate "Bench Press" reappeared on next launch.
    /// This pins the identity to what it was seeded as, so a rename is
    /// just a rename. Defaulted to nil so SwiftData's lightweight
    /// migration can add it to existing rows; `seedIfNeeded` backfills
    /// it on the next launch for anything already in the library.
    var seedName: String? = nil

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRawValue) ?? .other }
        set { muscleGroupRawValue = newValue.rawValue }
    }

    var secondaryMuscleGroup: MuscleGroup? {
        get { secondaryMuscleGroupRawValue.flatMap { MuscleGroup(rawValue: $0) } }
        set { secondaryMuscleGroupRawValue = newValue?.rawValue }
    }

    var loggingType: ExerciseLoggingType {
        get { ExerciseLoggingType(rawValue: loggingTypeRawValue) ?? .weightReps }
        set { loggingTypeRawValue = newValue.rawValue }
    }

    /// The specific muscles this exercise primarily trains, e.g. "Upper
    /// Chest" rather than just "Chest" — empty for anything not yet
    /// tagged at this level of detail.
    var primaryMuscleTargets: [MuscleTarget] {
        get { primaryMuscleTargetRawValues.compactMap { MuscleTarget(rawValue: $0) } }
        set { primaryMuscleTargetRawValues = newValue.map(\.rawValue) }
    }

    var secondaryMuscleTargets: [MuscleTarget] {
        get { secondaryMuscleTargetRawValues.compactMap { MuscleTarget(rawValue: $0) } }
        set { secondaryMuscleTargetRawValues = newValue.map(\.rawValue) }
    }

    /// Legacy convenience initializer — sets the broad `MuscleGroup`
    /// directly, with no specific muscle targets. Still used by tests
    /// and by call sites that don't need target-level detail; anything
    /// authoring real exercise data should use the targets-based
    /// initializer below instead, which derives the broad group
    /// automatically and keeps the two from disagreeing.
    init(
        name: String,
        isCustom: Bool = false,
        muscleGroup: MuscleGroup = .other,
        secondaryMuscleGroup: MuscleGroup? = nil,
        loggingType: ExerciseLoggingType = .weightReps
    ) {
        self.name = name
        self.isCustom = isCustom
        self.muscleGroupRawValue = muscleGroup.rawValue
        self.secondaryMuscleGroupRawValue = secondaryMuscleGroup?.rawValue
        self.loggingTypeRawValue = loggingType.rawValue
    }

    /// Targets-based initializer — the broad `muscleGroup` /
    /// `secondaryMuscleGroup` are derived from the first primary/
    /// secondary target respectively, so everything that already reads
    /// those (Progress-tab grouping, volume-by-muscle-group, exercise
    /// list icons) stays correct without needing to know targets exist.
    init(
        name: String,
        isCustom: Bool = false,
        primaryMuscleTargets: [MuscleTarget],
        secondaryMuscleTargets: [MuscleTarget] = [],
        loggingType: ExerciseLoggingType = .weightReps
    ) {
        self.name = name
        self.isCustom = isCustom
        self.muscleGroupRawValue = (primaryMuscleTargets.first?.muscleGroup ?? .other).rawValue
        self.secondaryMuscleGroupRawValue = secondaryMuscleTargets.first?.muscleGroup.rawValue
        self.loggingTypeRawValue = loggingType.rawValue
        self.primaryMuscleTargetRawValues = primaryMuscleTargets.map(\.rawValue)
        self.secondaryMuscleTargetRawValues = secondaryMuscleTargets.map(\.rawValue)
    }

    /// Updates both the specific targets and the broad group derived
    /// from them together, so they can't drift out of sync — used by
    /// the exercise edit form.
    func setMuscleTargets(primary: [MuscleTarget], secondary: [MuscleTarget]) {
        primaryMuscleTargets = primary
        secondaryMuscleTargets = secondary
        muscleGroupRawValue = (primary.first?.muscleGroup ?? .other).rawValue
        secondaryMuscleGroupRawValue = secondary.first?.muscleGroup.rawValue
    }
}
