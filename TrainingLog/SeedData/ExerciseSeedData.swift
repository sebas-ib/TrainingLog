import Foundation
import SwiftData

enum ExerciseSeedData {
    static let starterExercises: [(
        name: String,
        primary: [MuscleTarget],
        secondary: [MuscleTarget],
        type: ExerciseLoggingType
    )] = [
        // MARK: - Chest
        ("Bench Press", [.middleChest], [.frontDelts, .tricepsLateralHead, .tricepsMedialHead], .weightReps),
        ("Incline Bench Press", [.upperChest], [.frontDelts, .tricepsLateralHead, .tricepsMedialHead], .weightReps),
        ("Decline Bench Press", [.lowerChest], [.tricepsLateralHead, .tricepsMedialHead], .weightReps),
        ("Dumbbell Press", [.middleChest], [.frontDelts, .tricepsLateralHead, .tricepsMedialHead], .weightReps),
        ("Incline Dumbbell Press", [.upperChest], [.frontDelts], .weightReps),
        ("Push-Up", [.middleChest], [.tricepsLateralHead, .tricepsMedialHead, .frontDelts], .bodyweightReps),
        ("Incline Push-Up", [.lowerChest], [.tricepsLateralHead, .tricepsMedialHead], .bodyweightReps),
        ("Chest Fly", [.middleChest], [], .weightReps),
        ("Cable Crossover", [.lowerChest], [.middleChest], .weightReps),
        ("Dip", [.lowerChest], [.tricepsLateralHead, .tricepsMedialHead], .bodyweightReps),

        // MARK: - Back
        ("Deadlift", [.lowerBack], [.hamstrings, .glutes, .traps], .weightReps),
        ("Romanian Deadlift", [.hamstrings], [.glutes, .lowerBack], .weightReps),
        ("Pull-Up", [.lats], [.bicepsLongHead, .bicepsShortHead], .bodyweightReps),
        ("Chin-Up", [.lats], [.bicepsLongHead, .bicepsShortHead], .bodyweightReps),
        ("Lat Pulldown", [.lats], [.bicepsLongHead, .bicepsShortHead], .weightReps),
        ("Bent-Over Row", [.midBack], [.lats, .bicepsLongHead, .bicepsShortHead], .weightReps),
        ("Seated Cable Row", [.midBack], [.lats, .bicepsLongHead, .bicepsShortHead], .weightReps),
        ("T-Bar Row", [.midBack], [.lats], .weightReps),
        ("Single-Arm Dumbbell Row", [.lats], [.midBack, .bicepsLongHead, .bicepsShortHead], .weightReps),
        ("Shrug", [.traps], [], .weightReps),
        ("Hyperextension", [.lowerBack], [.glutes, .hamstrings], .bodyweightReps),

        // MARK: - Legs
        ("Squat", [.quads], [.glutes, .hamstrings], .weightReps),
        ("Front Squat", [.quads], [.glutes], .weightReps),
        ("Leg Press", [.quads], [.glutes, .hamstrings], .weightReps),
        ("Bulgarian Split Squat", [.quads], [.glutes], .weightReps),
        ("Lunges", [.quads], [.glutes, .hamstrings], .weightReps),
        ("Leg Curl", [.hamstrings], [], .weightReps),
        ("Leg Extension", [.quads], [], .weightReps),
        ("Hip Thrust", [.glutes], [.hamstrings], .weightReps),
        ("Glute Bridge", [.glutes], [.hamstrings], .bodyweightReps),
        ("Calf Raise", [.calves], [], .weightReps),
        ("Seated Calf Raise", [.calves], [], .weightReps),

        // MARK: - Shoulders
        ("Overhead Press", [.frontDelts], [.sideDelts, .tricepsLongHead, .tricepsLateralHead], .weightReps),
        ("Arnold Press", [.frontDelts], [.sideDelts], .weightReps),
        ("Lateral Raise", [.sideDelts], [], .weightReps),
        ("Cable Lateral Raise", [.sideDelts], [], .weightReps),
        ("Front Raise", [.frontDelts], [], .weightReps),
        ("Rear Delt Fly", [.rearDelts], [], .weightReps),
        ("Face Pull", [.rearDelts], [.traps], .weightReps),
        ("Upright Row", [.sideDelts], [.traps], .weightReps),

        // MARK: - Arms
        ("Bicep Curl", [.bicepsLongHead, .bicepsShortHead], [.forearmFlexors], .weightReps),
        ("Hammer Curl", [.bicepsLongHead], [.brachioradialis], .weightReps),
        ("Preacher Curl", [.bicepsShortHead], [], .weightReps),
        ("Concentration Curl", [.bicepsShortHead], [], .weightReps),
        ("Cable Curl", [.bicepsLongHead, .bicepsShortHead], [.forearmFlexors], .weightReps),
        ("Tricep Pushdown", [.tricepsLateralHead, .tricepsLongHead], [], .weightReps),
        ("Overhead Tricep Extension", [.tricepsLongHead], [], .weightReps),
        ("Skull Crusher", [.tricepsLongHead, .tricepsLateralHead], [], .weightReps),
        ("Close-Grip Bench Press", [.tricepsLateralHead, .tricepsMedialHead], [.middleChest], .weightReps),
        ("Tricep Dip", [.tricepsLateralHead, .tricepsMedialHead], [.lowerChest], .bodyweightReps),
        ("Wrist Curl", [.forearmFlexors], [], .weightReps),

        // MARK: - Core
        ("Plank", [.abs], [.obliques], .time),
        ("Weighted Plank", [.abs], [.obliques], .timeWeight),
        ("Side Plank", [.obliques], [.abs], .time),
        ("Crunch", [.abs], [], .repsOnly),
        ("Bicycle Crunch", [.abs], [.obliques], .repsOnly),
        ("Russian Twist", [.obliques], [.abs], .repsOnly),
        ("Hanging Leg Raise", [.abs], [.obliques], .bodyweightReps),
        ("Sit-Up", [.abs], [], .repsOnly),
        ("Ab Wheel Rollout", [.abs], [.obliques], .repsOnly),
        ("Mountain Climber", [.abs], [.quads], .repsOnly),

        // MARK: - Conditioning
        ("Running", [], [], .distanceTime),
        ("Cycling", [], [], .distanceTime),
        ("Rowing Machine", [], [.lats, .quads], .distanceTime),
        ("Jump Rope", [.calves], [], .time),
        ("Farmer's Carry", [.forearmFlexors, .brachioradialis], [.traps], .timeWeight),
        ("Sled Push", [.quads], [.glutes], .distanceTime)
    ]
}

extension ExerciseSeedData {
    /// Inserts any starter exercise that isn't already present (matched
    /// by name, case-insensitively) and, separately, backfills specific
    /// muscle targets onto any *non-custom* exercise that matches a
    /// starter name but doesn't have targets yet — covers upgrading a
    /// library seeded before target-level detail existed, without ever
    /// touching an exercise the user created themselves (even if it
    /// happens to share a name) or one that's already been tagged.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let existingByName = Dictionary(
            existing.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var didChange = false

        for entry in starterExercises {
            if let match = existingByName[entry.name.lowercased()] {
                if !match.isCustom, match.primaryMuscleTargets.isEmpty {
                    match.setMuscleTargets(primary: entry.primary, secondary: entry.secondary)
                    didChange = true
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
            context.insert(exercise)
            didChange = true
        }

        if didChange {
            try? context.save()
        }
    }
}
