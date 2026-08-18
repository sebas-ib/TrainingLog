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
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, newPhase in
            // A finished rest/set timer's Live Activity is left up to
            // linger (see WorkoutTimerActivityManager.complete()) so it
            // doesn't vanish before the user checks their phone — this
            // is the other half: clear it as soon as they're actually
            // back in the app, rather than leaving it to the system's
            // own multi-hour grace period.
            if newPhase == .active {
                WorkoutTimerActivityManager.shared.dismissIfCompleted()
            }
        }
    }
}
