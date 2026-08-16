//
//  ExerciseListProgressView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct ProgressView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var searchText = ""
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var groupedExercises: [MuscleGroup: [Exercise]] {
        Dictionary(grouping: filteredExercises, by: { $0.muscleGroup })
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section {
                        ConsistencyGraphView()
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                    }
                }
                
                if filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        if let groupExercises = groupedExercises[group], !groupExercises.isEmpty {
                            Section {
                                ForEach(groupExercises) { exercise in
                                    NavigationLink {
                                        ExerciseProgressView(exercise: exercise)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: group.icon)
                                                .font(.subheadline)
                                                .foregroundStyle(Theme.accent)
                                                .frame(width: 22)
                                            
                                            Text(exercise.name)
                                            
                                            if exercise.isCustom {
                                                Spacer()
                                                Text("Custom")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            } header: {
                                Text(group.rawValue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
    }
}
