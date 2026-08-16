import Foundation
import SwiftData

enum ExerciseSeedData {
    static let starterExercises: [(name: String, primary: MuscleGroup, secondary: MuscleGroup?, type: ExerciseLoggingType)] = [
        // Chest
        ("Bench Press", .chest, .arms, .weightReps),
        ("Incline Bench Press", .chest, .shoulders, .weightReps),
        ("Dumbbell Press", .chest, .arms, .weightReps),
        ("Push-Up", .chest, .arms, .bodyweightReps),
        ("Chest Fly", .chest, nil, .weightReps),

        // Back
        ("Deadlift", .back, .legs, .weightReps),
        ("Pull-Up", .back, .arms, .bodyweightReps),
        ("Lat Pulldown", .back, .arms, .weightReps),
        ("Bent-Over Row", .back, .arms, .weightReps),
        ("Seated Cable Row", .back, .arms, .weightReps),

        // Legs
        ("Squat", .legs, .core, .weightReps),
        ("Leg Press", .legs, nil, .weightReps),
        ("Lunges", .legs, nil, .weightReps),
        ("Leg Curl", .legs, nil, .weightReps),
        ("Leg Extension", .legs, nil, .weightReps),
        ("Calf Raise", .legs, nil, .weightReps),

        // Shoulders
        ("Overhead Press", .shoulders, .arms, .weightReps),
        ("Lateral Raise", .shoulders, nil, .weightReps),
        ("Front Raise", .shoulders, nil, .weightReps),
        ("Face Pull", .shoulders, .back, .weightReps),

        // Arms
        ("Bicep Curl", .arms, nil, .weightReps),
        ("Hammer Curl", .arms, nil, .weightReps),
        ("Tricep Pushdown", .arms, nil, .weightReps),
        ("Tricep Dip", .arms, .chest, .bodyweightReps),
        ("Skull Crusher", .arms, nil, .weightReps),

        // Core
        ("Plank", .core, nil, .time),
        ("Crunch", .core, nil, .repsOnly),
        ("Russian Twist", .core, nil, .repsOnly),
        ("Hanging Leg Raise", .core, .back, .bodyweightReps)
    ]
}

extension ExerciseSeedData {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else {
            migrateUntaggedExercisesIfNeeded(context: context)
            return
        }
        
        for entry in starterExercises {
            let exercise = Exercise(
                name: entry.name,
                isCustom: false,
                muscleGroup: entry.primary,
                secondaryMuscleGroup: entry.secondary,
                loggingType: entry.type
            )
            context.insert(exercise)
        }
        
        try? context.save()
    }
    
    @MainActor
    static func migrateUntaggedExercisesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        guard let allExercises = try? context.fetch(descriptor) else { return }
        
        let nameToEntry = Dictionary(uniqueKeysWithValues: starterExercises.map { ($0.name, $0) })
        var didUpdate = false
        
        for exercise in allExercises {
            if exercise.muscleGroupRawValue.isEmpty, let match = nameToEntry[exercise.name] {
                exercise.muscleGroup = match.primary
                exercise.secondaryMuscleGroup = match.secondary
                exercise.loggingType = match.type
                didUpdate = true
            }
        }
        
        if didUpdate {
            try? context.save()
        }
    }
}
