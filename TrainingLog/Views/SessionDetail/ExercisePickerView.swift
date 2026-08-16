//
//  ExercisePickerView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var searchText = ""
    @State private var showingNewExerciseSheet = false
    
    let onSelect: (Exercise) -> Void
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var exactMatchExists: Bool {
        exercises.contains { $0.name.localizedCaseInsensitiveCompare(searchText) == .orderedSame }
    }
    
    private var groupedExercises: [MuscleGroup: [Exercise]] {
        Dictionary(grouping: filteredExercises, by: { $0.muscleGroup })
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty && !exactMatchExists {
                    Button {
                        showingNewExerciseSheet = true
                    } label: {
                        Label("Add \"\(searchText)\" as new exercise", systemImage: "plus.circle.fill")
                    }
                }
                
                ForEach(MuscleGroup.allCases, id: \.self) { group in
                    if let groupExercises = groupedExercises[group], !groupExercises.isEmpty {
                        Section(group.rawValue) {
                            ForEach(groupExercises) { exercise in
                                Button {
                                    onSelect(exercise)
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.name)
                                                .foregroundStyle(.primary)
                                            if let secondary = exercise.secondaryMuscleGroup {
                                                Text("Also: \(secondary.rawValue)")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        if exercise.isCustom {
                                            Spacer()
                                            Text("Custom")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewExerciseSheet) {
                NewExerciseView(name: searchText) { exercise in
                    onSelect(exercise)
                    dismiss()
                }
            }
        }
    }
}
