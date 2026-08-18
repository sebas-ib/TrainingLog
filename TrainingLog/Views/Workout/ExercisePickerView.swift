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
    @State private var duplicateSuggestion: Exercise?

    let onSelect: (Exercise) -> Void

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var exactMatchExists: Bool {
        exercises.contains { $0.name.localizedCaseInsensitiveCompare(searchText) == .orderedSame }
    }

    /// The closest existing exercise name to the current search text, if
    /// it's close enough to plausibly be the same exercise — a typo or a
    /// pluralization — rather than something genuinely different. Used
    /// to nudge the user before they create a near-duplicate like
    /// "Bicep Curl" alongside an existing "Bicep Curls".
    private var duplicateCandidate: Exercise? {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3, !exactMatchExists else { return nil }

        return exercises
            .map { ($0, $0.name.levenshteinDistance(to: trimmed)) }
            .filter { _, distance in distance <= max(1, trimmed.count / 4) }
            .min { $0.1 < $1.1 }?
            .0
    }

    private var groupedExercises: [MuscleGroup: [Exercise]] {
        Dictionary(grouping: filteredExercises, by: { $0.muscleGroup })
    }

    private var duplicateSuggestionBinding: Binding<Bool> {
        Binding(
            get: { duplicateSuggestion != nil },
            set: { isPresented in
                if !isPresented { duplicateSuggestion = nil }
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty && !exactMatchExists {
                    Button {
                        if let duplicateCandidate {
                            duplicateSuggestion = duplicateCandidate
                        } else {
                            showingNewExerciseSheet = true
                        }
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
            .confirmationDialog(
                "Did you mean \"\(duplicateSuggestion?.name ?? "")\"?",
                isPresented: duplicateSuggestionBinding,
                presenting: duplicateSuggestion
            ) { suggestion in
                Button("Use \"\(suggestion.name)\"") {
                    onSelect(suggestion)
                    dismiss()
                }
                Button("Create \"\(searchText)\" Anyway") {
                    showingNewExerciseSheet = true
                }
                Button("Cancel", role: .cancel) {}
            } message: { suggestion in
                Text("You already have \"\(suggestion.name)\" in your exercise library.")
            }
        }
    }
}
