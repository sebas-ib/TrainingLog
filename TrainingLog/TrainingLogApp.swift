//
//  TrainingLogApp.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/15/26.
//
import SwiftUI
import SwiftData

@main
struct TrainingLogApp: App {
    @StateObject private var unitSettings = UnitSettings()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutDay.self,
            WorkoutSession.self,
            WorkoutExercise.self,
            ExerciseSet.self,
            Exercise.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(unitSettings)
        
    }
}
