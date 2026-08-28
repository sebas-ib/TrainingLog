//
//  ExerciseVariant.swift
//  TrainingLog
//

import Foundation
import SwiftData

/// A meaningfully different way of performing the same movement — leg
/// press with a high vs. low foot position, a row with a wide vs. close
/// grip — without splitting it into separate `Exercise` entries.
///
/// Everything here is an *override*: an empty target list or a nil
/// logging type means "inherit whatever the parent exercise says." That
/// makes three useful shapes fall out of one model:
///
/// - **Targeting variants** override the muscle targets (high-foot leg
///   press trains hamstrings where the parent trains quads).
/// - **Format variants** override the logging type (a weighted plank is
///   the same movement as a plank, timed with load rather than without).
/// - **History-only variants** override nothing at all, and exist purely
///   so the two get their own progress, records, and previous-set
///   reference — pull-up vs. chin-up, or a paused/tempo version of a
///   lift.
@Model
final class ExerciseVariant {
    var name: String
    var order: Int = 0
    var isCustom: Bool = false

    /// Stable identity for a seeded variant, independent of `name` — the
    /// same trick `Exercise.seedName` uses, so renaming a stock variant
    /// doesn't make the seeder think it's missing and re-add it.
    var seedKey: String? = nil

    /// Empty means "inherit the parent's targets." A variant that
    /// overrides them replaces the parent's list outright rather than
    /// adding to it: a high-foot leg press trains hamstrings *instead
    /// of* quads, and layering the two would describe neither.
    var primaryMuscleTargetRawValues: [String] = []
    var secondaryMuscleTargetRawValues: [String] = []

    /// nil means "inherit the parent's logging type."
    var loggingTypeRawValue: String? = nil

    var exercise: Exercise?

    init(
        name: String,
        order: Int = 0,
        isCustom: Bool = false,
        seedKey: String? = nil,
        primaryMuscleTargets: [MuscleTarget] = [],
        secondaryMuscleTargets: [MuscleTarget] = [],
        loggingType: ExerciseLoggingType? = nil
    ) {
        self.name = name
        self.order = order
        self.isCustom = isCustom
        self.seedKey = seedKey
        self.primaryMuscleTargetRawValues = primaryMuscleTargets.map(\.rawValue)
        self.secondaryMuscleTargetRawValues = secondaryMuscleTargets.map(\.rawValue)
        self.loggingTypeRawValue = loggingType?.rawValue
    }

    var primaryMuscleTargets: [MuscleTarget] {
        get { primaryMuscleTargetRawValues.compactMap { MuscleTarget(rawValue: $0) } }
        set { primaryMuscleTargetRawValues = newValue.map(\.rawValue) }
    }

    var secondaryMuscleTargets: [MuscleTarget] {
        get { secondaryMuscleTargetRawValues.compactMap { MuscleTarget(rawValue: $0) } }
        set { secondaryMuscleTargetRawValues = newValue.map(\.rawValue) }
    }

    var loggingType: ExerciseLoggingType? {
        get { loggingTypeRawValue.flatMap { ExerciseLoggingType(rawValue: $0) } }
        set { loggingTypeRawValue = newValue?.rawValue }
    }
}

extension ExerciseVariant: Orderable {}
