import Foundation
import SwiftData

enum ExerciseSeedData {

    /// A seeded variant. Empty target lists and a nil `type` mean
    /// "inherit the parent" — see `ExerciseVariant`. Several entries here
    /// override nothing at all and exist purely to give two ways of doing
    /// the same movement their own history (Pull-Up's grips, Calf Raise's
    /// standing vs. seated).
    struct StarterVariant {
        let name: String
        var primary: [MuscleTarget] = []
        var secondary: [MuscleTarget] = []
        var type: ExerciseLoggingType? = nil
    }

    struct StarterExercise {
        let name: String
        let primary: [MuscleTarget]
        let secondary: [MuscleTarget]
        let type: ExerciseLoggingType
        var variants: [StarterVariant] = []
    }

    /// Where an exercise has variants, the first one is the plain/default
    /// way of doing it and deliberately overrides nothing — so the picker
    /// offers "Flat / Incline / Decline" rather than the more confusing
    /// "unspecified / Incline / Decline".
    static let starterExercises: [StarterExercise] = [
        // MARK: - Chest
        StarterExercise(
            name: "Bench Press",
            primary: [.middleChest],
            secondary: [.frontDelts, .tricepsLateralHead, .tricepsMedialHead],
            type: .weightReps,
            variants: [
                StarterVariant(name: "Flat"),
                StarterVariant(
                    name: "Incline",
                    primary: [.upperChest],
                    secondary: [.frontDelts, .tricepsLateralHead, .tricepsMedialHead]
                ),
                StarterVariant(
                    name: "Decline",
                    primary: [.lowerChest],
                    secondary: [.tricepsLateralHead, .tricepsMedialHead]
                ),
                StarterVariant(
                    name: "Close-Grip",
                    primary: [.tricepsLateralHead, .tricepsMedialHead],
                    secondary: [.middleChest]
                )
            ]
        ),
        StarterExercise(
            name: "Dumbbell Press",
            primary: [.middleChest],
            secondary: [.frontDelts, .tricepsLateralHead, .tricepsMedialHead],
            type: .weightReps,
            variants: [
                StarterVariant(name: "Flat"),
                StarterVariant(
                    name: "Incline",
                    primary: [.upperChest],
                    secondary: [.frontDelts]
                )
            ]
        ),
        StarterExercise(
            name: "Push-Up",
            primary: [.middleChest],
            secondary: [.tricepsLateralHead, .tricepsMedialHead, .frontDelts],
            type: .bodyweightReps,
            variants: [
                StarterVariant(name: "Standard"),
                StarterVariant(
                    name: "Incline",
                    primary: [.lowerChest],
                    secondary: [.tricepsLateralHead, .tricepsMedialHead]
                )
            ]
        ),
        StarterExercise(
            name: "Dip",
            primary: [.lowerChest],
            secondary: [.tricepsLateralHead, .tricepsMedialHead],
            type: .bodyweightReps,
            variants: [
                StarterVariant(name: "Chest"),
                StarterVariant(
                    name: "Triceps",
                    primary: [.tricepsLateralHead, .tricepsMedialHead],
                    secondary: [.lowerChest]
                )
            ]
        ),
        StarterExercise(name: "Chest Fly", primary: [.middleChest], secondary: [], type: .weightReps),
        StarterExercise(name: "Cable Crossover", primary: [.lowerChest], secondary: [.middleChest], type: .weightReps),

        // MARK: - Back
        StarterExercise(
            name: "Deadlift",
            primary: [.lowerBack],
            secondary: [.hamstrings, .glutes, .traps],
            type: .weightReps,
            variants: [
                StarterVariant(name: "Conventional"),
                StarterVariant(
                    name: "Sumo",
                    primary: [.quads, .glutes],
                    secondary: [.adductors, .lowerBack, .hamstrings]
                )
            ]
        ),
        StarterExercise(name: "Romanian Deadlift", primary: [.hamstrings], secondary: [.glutes, .lowerBack], type: .weightReps),
        StarterExercise(
            name: "Pull-Up",
            primary: [.lats],
            secondary: [.bicepsLongHead, .bicepsShortHead],
            type: .bodyweightReps,
            variants: [
                StarterVariant(name: "Overhand"),
                StarterVariant(name: "Chin-Up"),
                StarterVariant(name: "Neutral Grip")
            ]
        ),
        StarterExercise(
            name: "Lat Pulldown",
            primary: [.lats],
            secondary: [.bicepsLongHead, .bicepsShortHead],
            type: .weightReps,
            variants: [
                StarterVariant(name: "Wide Grip"),
                StarterVariant(
                    name: "Close Grip",
                    primary: [.lats],
                    secondary: [.midBack, .bicepsLongHead, .bicepsShortHead]
                ),
                StarterVariant(name: "Neutral Grip")
            ]
        ),
        StarterExercise(
            name: "Bent-Over Row",
            primary: [.midBack],
            secondary: [.lats, .bicepsLongHead, .bicepsShortHead],
            type: .weightReps,
            variants: [
                StarterVariant(
                    name: "Overhand",
                    primary: [.midBack],
                    secondary: [.rearDelts, .lats]
                ),
                StarterVariant(
                    name: "Underhand",
                    primary: [.lats],
                    secondary: [.midBack, .bicepsLongHead, .bicepsShortHead]
                )
            ]
        ),
        StarterExercise(
            name: "Seated Cable Row",
            primary: [.midBack],
            secondary: [.lats, .bicepsLongHead, .bicepsShortHead],
            type: .weightReps,
            variants: [
                StarterVariant(
                    name: "Wide Grip",
                    primary: [.midBack],
                    secondary: [.rearDelts, .lats]
                ),
                StarterVariant(
                    name: "Close Grip",
                    primary: [.lats],
                    secondary: [.midBack, .bicepsLongHead, .bicepsShortHead]
                )
            ]
        ),
        StarterExercise(name: "T-Bar Row", primary: [.midBack], secondary: [.lats], type: .weightReps),
        StarterExercise(name: "Single-Arm Dumbbell Row", primary: [.lats], secondary: [.midBack, .bicepsLongHead, .bicepsShortHead], type: .weightReps),
        StarterExercise(name: "Shrug", primary: [.traps], secondary: [], type: .weightReps),
        StarterExercise(name: "Hyperextension", primary: [.lowerBack], secondary: [.glutes, .hamstrings], type: .bodyweightReps),

        // MARK: - Legs
        StarterExercise(
            name: "Squat",
            primary: [.quads],
            secondary: [.glutes, .hamstrings],
            type: .weightReps,
            variants: [
                StarterVariant(name: "High Bar"),
                StarterVariant(
                    name: "Low Bar",
                    primary: [.quads],
                    secondary: [.glutes, .hamstrings, .lowerBack]
                ),
                StarterVariant(
                    name: "Front",
                    primary: [.quads],
                    secondary: [.glutes]
                )
            ]
        ),
        StarterExercise(
            name: "Leg Press",
            primary: [.quads],
            secondary: [.glutes, .hamstrings],
            type: .weightReps,
            variants: [
                StarterVariant(name: "Mid Foot"),
                StarterVariant(
                    name: "High Foot",
                    primary: [.hamstrings, .glutes],
                    secondary: [.quads]
                ),
                StarterVariant(
                    name: "Low Foot",
                    primary: [.quads],
                    secondary: [.glutes]
                ),
                StarterVariant(
                    name: "Wide Stance",
                    primary: [.adductors, .quads],
                    secondary: [.glutes]
                )
            ]
        ),
        StarterExercise(name: "Bulgarian Split Squat", primary: [.quads], secondary: [.glutes], type: .weightReps),
        StarterExercise(name: "Lunges", primary: [.quads], secondary: [.glutes, .hamstrings], type: .weightReps),
        StarterExercise(name: "Leg Curl", primary: [.hamstrings], secondary: [], type: .weightReps),
        StarterExercise(name: "Leg Extension", primary: [.quads], secondary: [], type: .weightReps),
        StarterExercise(name: "Hip Thrust", primary: [.glutes], secondary: [.hamstrings], type: .weightReps),
        StarterExercise(name: "Glute Bridge", primary: [.glutes], secondary: [.hamstrings], type: .bodyweightReps),
        StarterExercise(name: "Hip Abduction Machine", primary: [.abductors], secondary: [.glutes], type: .weightReps),
        StarterExercise(name: "Hip Adduction Machine", primary: [.adductors], secondary: [], type: .weightReps),
        StarterExercise(
            name: "Calf Raise",
            primary: [.calves],
            secondary: [],
            type: .weightReps,
            variants: [
                StarterVariant(name: "Standing"),
                StarterVariant(name: "Seated")
            ]
        ),

        // MARK: - Shoulders
        StarterExercise(name: "Overhead Press", primary: [.frontDelts], secondary: [.sideDelts, .tricepsLongHead, .tricepsLateralHead], type: .weightReps),
        StarterExercise(name: "Arnold Press", primary: [.frontDelts], secondary: [.sideDelts], type: .weightReps),
        StarterExercise(name: "Lateral Raise", primary: [.sideDelts], secondary: [], type: .weightReps),
        StarterExercise(name: "Cable Lateral Raise", primary: [.sideDelts], secondary: [], type: .weightReps),
        StarterExercise(name: "Front Raise", primary: [.frontDelts], secondary: [], type: .weightReps),
        StarterExercise(name: "Rear Delt Fly", primary: [.rearDelts], secondary: [], type: .weightReps),
        StarterExercise(name: "Face Pull", primary: [.rearDelts], secondary: [.traps], type: .weightReps),
        StarterExercise(name: "Upright Row", primary: [.sideDelts], secondary: [.traps], type: .weightReps),

        // MARK: - Arms
        StarterExercise(name: "Bicep Curl", primary: [.bicepsLongHead, .bicepsShortHead], secondary: [.forearmFlexors], type: .weightReps),
        StarterExercise(name: "Hammer Curl", primary: [.bicepsLongHead], secondary: [.brachioradialis], type: .weightReps),
        StarterExercise(name: "Preacher Curl", primary: [.bicepsShortHead], secondary: [], type: .weightReps),
        StarterExercise(name: "Concentration Curl", primary: [.bicepsShortHead], secondary: [], type: .weightReps),
        StarterExercise(name: "Cable Curl", primary: [.bicepsLongHead, .bicepsShortHead], secondary: [.forearmFlexors], type: .weightReps),
        StarterExercise(name: "Tricep Pushdown", primary: [.tricepsLateralHead, .tricepsLongHead], secondary: [], type: .weightReps),
        StarterExercise(name: "Overhead Tricep Extension", primary: [.tricepsLongHead], secondary: [], type: .weightReps),
        StarterExercise(name: "Skull Crusher", primary: [.tricepsLongHead, .tricepsLateralHead], secondary: [], type: .weightReps),
        StarterExercise(name: "Wrist Curl", primary: [.forearmFlexors], secondary: [], type: .weightReps),

        // MARK: - Core
        StarterExercise(
            name: "Plank",
            primary: [.abs],
            secondary: [.obliques],
            type: .time,
            variants: [
                StarterVariant(name: "Standard"),
                // The one seeded variant that overrides the logging type:
                // same movement, timed with load rather than without.
                StarterVariant(name: "Weighted", type: .timeWeight),
                StarterVariant(
                    name: "Side",
                    primary: [.obliques],
                    secondary: [.abs]
                )
            ]
        ),
        StarterExercise(name: "Crunch", primary: [.abs], secondary: [], type: .repsOnly),
        StarterExercise(name: "Bicycle Crunch", primary: [.abs], secondary: [.obliques], type: .repsOnly),
        StarterExercise(name: "Russian Twist", primary: [.obliques], secondary: [.abs], type: .repsOnly),
        StarterExercise(name: "Hanging Leg Raise", primary: [.abs], secondary: [.obliques], type: .bodyweightReps),
        StarterExercise(name: "Sit-Up", primary: [.abs], secondary: [], type: .repsOnly),
        StarterExercise(name: "Ab Wheel Rollout", primary: [.abs], secondary: [.obliques], type: .repsOnly),
        StarterExercise(name: "Mountain Climber", primary: [.abs], secondary: [.quads], type: .repsOnly),

        // MARK: - Conditioning
        StarterExercise(name: "Running", primary: [], secondary: [], type: .distanceTime),
        StarterExercise(name: "Cycling", primary: [], secondary: [], type: .distanceTime),
        StarterExercise(name: "Rowing Machine", primary: [], secondary: [.lats, .quads], type: .distanceTime),
        StarterExercise(name: "Jump Rope", primary: [.calves], secondary: [], type: .time),
        StarterExercise(name: "Farmer's Carry", primary: [.forearmFlexors, .brachioradialis], secondary: [.traps], type: .timeWeight),
        StarterExercise(name: "Sled Push", primary: [.quads], secondary: [.glutes], type: .distanceTime)
    ]
}

extension ExerciseSeedData {
    /// Inserts any starter exercise that isn't already present, backfills
    /// muscle targets onto any *non-custom* exercise that matches a
    /// starter but has none yet, and adds any seeded variants the
    /// exercise is missing.
    ///
    /// Matching prefers `seedName`/`seedKey` over the current name, which
    /// is what makes renaming a stock exercise or variant safe: the
    /// seeder recognizes it by where it came from rather than by what
    /// it's currently called, so it won't be re-inserted as a duplicate.
    /// An exercise the user created themselves is never touched, even if
    /// it happens to share a starter's name.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let existingBySeedName = Dictionary(
            existing.compactMap { exercise in
                exercise.seedName.map { ($0.lowercased(), exercise) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        let existingByName = Dictionary(
            existing.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var didChange = false

        for entry in starterExercises {
            let key = entry.name.lowercased()

            if let match = existingBySeedName[key] ?? existingByName[key] {
                if !match.isCustom {
                    if match.seedName == nil {
                        match.seedName = entry.name
                        didChange = true
                    }
                    if match.primaryMuscleTargets.isEmpty {
                        match.setMuscleTargets(primary: entry.primary, secondary: entry.secondary)
                        didChange = true
                    }
                    if syncVariants(of: match, to: entry.variants, context: context) {
                        didChange = true
                    }
                }
                continue
            }

            let exercise = Exercise(
                name: entry.name,
                isCustom: false,
                primaryMuscleTargets: entry.primary,
                secondaryMuscleTargets: entry.secondary,
                loggingType: entry.type
            )
            exercise.seedName = entry.name
            context.insert(exercise)
            _ = syncVariants(of: exercise, to: entry.variants, context: context)
            didChange = true
        }

        if didChange {
            try? context.save()
        }
    }

    /// Adds any seeded variant `exercise` doesn't have yet, matched by
    /// `seedKey` first so a renamed one isn't re-added. Existing variants
    /// are left exactly as they are — a user may have retargeted one —
    /// and variants the user added themselves are never removed, so this
    /// only ever grows the list.
    @MainActor
    @discardableResult
    private static func syncVariants(
        of exercise: Exercise,
        to entries: [StarterVariant],
        context: ModelContext
    ) -> Bool {
        guard !entries.isEmpty else { return false }

        let existing = exercise.variants
        let bySeedKey = Set(existing.compactMap { $0.seedKey?.lowercased() })
        let byName = Set(existing.map { $0.name.lowercased() })

        var didChange = false
        var nextOrder = (existing.map(\.order).max() ?? 0) + 1

        for entry in entries {
            let key = entry.name.lowercased()
            guard !bySeedKey.contains(key), !byName.contains(key) else { continue }

            let variant = ExerciseVariant(
                name: entry.name,
                order: nextOrder,
                isCustom: false,
                seedKey: entry.name,
                primaryMuscleTargets: entry.primary,
                secondaryMuscleTargets: entry.secondary,
                loggingType: entry.type
            )
            context.insert(variant)
            exercise.variants.append(variant)

            nextOrder += 1
            didChange = true
        }

        return didChange
    }
}
