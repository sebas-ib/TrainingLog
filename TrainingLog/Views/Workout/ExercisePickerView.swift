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
    @Query private var allWorkoutExercises: [WorkoutExercise]

    @State private var searchText = ""
    @State private var showingNewExerciseSheet = false
    @State private var duplicateSuggestion: Exercise?
    @State private var selectedGroup: MuscleGroup?
    @State private var selectedTarget: MuscleTarget?
    @State private var exercisePendingDeletion: Exercise?
    @State private var exerciseBlockedFromDeletion: Exercise?

    let onSelect: (Exercise) -> Void

    private var filteredExercises: [Exercise] {
        var result = exercises

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        if let selectedTarget {
            result = result.filter { $0.primaryMuscleTargets.contains(selectedTarget) }
        } else if let selectedGroup {
            result = result.filter { $0.muscleGroup == selectedGroup }
        }

        return result
    }

    /// Only groups (and, once a group is picked, targets) that at least
    /// one exercise actually has — no point offering a filter chip that
    /// can only ever produce an empty list.
    private var availableGroups: [MuscleGroup] {
        let present = Set(exercises.map(\.muscleGroup))
        return MuscleGroup.allCases.filter { present.contains($0) }
    }

    private var availableTargets: [MuscleTarget] {
        guard let selectedGroup else { return [] }
        let present = Set(exercises.flatMap(\.primaryMuscleTargets))
        return MuscleTarget.allCases.filter { $0.muscleGroup == selectedGroup && present.contains($0) }
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

    private var deletionAlertBinding: Binding<Bool> {
        Binding(
            get: { exercisePendingDeletion != nil },
            set: { isPresented in
                if !isPresented { exercisePendingDeletion = nil }
            }
        )
    }

    private var blockedDeletionAlertBinding: Binding<Bool> {
        Binding(
            get: { exerciseBlockedFromDeletion != nil },
            set: { isPresented in
                if !isPresented { exerciseBlockedFromDeletion = nil }
            }
        )
    }

    // MARK: - Deletion

    private func hasHistory(_ exercise: Exercise) -> Bool {
        allWorkoutExercises.contains { $0.exercise.persistentModelID == exercise.persistentModelID }
    }

    private func requestDelete(_ exercise: Exercise) {
        if hasHistory(exercise) {
            exerciseBlockedFromDeletion = exercise
        } else {
            exercisePendingDeletion = exercise
        }
    }

    private func confirmDelete() {
        guard let exercise = exercisePendingDeletion else { return }
        modelContext.delete(exercise)
        try? modelContext.save()
        exercisePendingDeletion = nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                filterChipRow(
                    items: availableGroups,
                    title: { $0.rawValue },
                    isSelected: { $0 == selectedGroup },
                    allLabel: "All",
                    isAllSelected: selectedGroup == nil,
                    onSelectAll: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            selectedGroup = nil
                            selectedTarget = nil
                        }
                    },
                    onSelect: { group in
                        withAnimation(.easeOut(duration: 0.15)) {
                            selectedGroup = (selectedGroup == group) ? nil : group
                            selectedTarget = nil
                        }
                    }
                )

                if !availableTargets.isEmpty {
                    filterChipRow(
                        items: availableTargets,
                        title: { $0.displayName },
                        isSelected: { $0 == selectedTarget },
                        allLabel: "All \(selectedGroup?.rawValue ?? "")",
                        isAllSelected: selectedTarget == nil,
                        onSelectAll: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedTarget = nil
                            }
                        },
                        onSelect: { target in
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedTarget = (selectedTarget == target) ? nil : target
                            }
                        }
                    )
                }

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

                    if selectedGroup != nil {
                        Section {
                            ForEach(filteredExercises) { exercise in
                                exerciseRow(exercise)
                            }
                        }
                    } else {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            if let groupExercises = groupedExercises[group], !groupExercises.isEmpty {
                                Section(group.rawValue) {
                                    ForEach(groupExercises) { exercise in
                                        exerciseRow(exercise)
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
                ExerciseFormView(name: searchText) { exercise in
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
            .alert(
                "Delete \(exercisePendingDeletion?.name ?? "Exercise")?",
                isPresented: deletionAlertBinding
            ) {
                Button("Cancel", role: .cancel) {
                    exercisePendingDeletion = nil
                }
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
            } message: {
                Text("This removes it from your exercise library. This can't be undone.")
            }
            .alert(
                "Can't Delete \(exerciseBlockedFromDeletion?.name ?? "Exercise")",
                isPresented: blockedDeletionAlertBinding
            ) {
                Button("OK", role: .cancel) {
                    exerciseBlockedFromDeletion = nil
                }
            } message: {
                Text("This exercise has logged history, so it can't be deleted. Edit it instead if you want to change its name or muscles.")
            }
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
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
        .swipeActions(edge: .trailing) {
            // Only custom exercises — a stock one would just reappear on
            // next launch via seeding, which would read as "deletion
            // didn't work" rather than the deliberate protection it is.
            if exercise.isCustom {
                Button(role: .destructive) {
                    requestDelete(exercise)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Filter Chips

    /// A horizontally scrolling row of chips — an "All" chip plus one per
    /// item — used both for the muscle-group row and, once a group is
    /// picked, the specific-muscle row beneath it.
    @ViewBuilder
    private func filterChipRow<T: Hashable>(
        items: [T],
        title: @escaping (T) -> String,
        isSelected: @escaping (T) -> Bool,
        allLabel: String,
        isAllSelected: Bool,
        onSelectAll: @escaping () -> Void,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: allLabel, isSelected: isAllSelected, action: onSelectAll)

                ForEach(items, id: \.self) { item in
                    FilterChip(title: title(item), isSelected: isSelected(item)) {
                        onSelect(item)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? Theme.accent : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}
