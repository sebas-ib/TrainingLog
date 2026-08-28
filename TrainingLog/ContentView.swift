//
//  ContentView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            BalanceView()
                .tabItem {
                    Label("Balance", systemImage: "target")
                }
        }
        .tint(Theme.accent)
        .task {
            ExerciseSeedData.seedIfNeeded(context: modelContext)
        }
    }
}

#Preview {
    let schema = Schema([
        WorkoutDay.self,
        WorkoutSession.self,
        WorkoutExercise.self,
        ExerciseSet.self,
        Exercise.self,
        ExerciseVariant.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return ContentView()
        .modelContainer(container)
        .environmentObject(UnitSettings())
}
