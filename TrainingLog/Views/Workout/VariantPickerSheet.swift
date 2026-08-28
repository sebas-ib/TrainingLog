//
//  VariantPickerSheet.swift
//  TrainingLog
//

import SwiftUI
import SwiftData

/// The one extra tap between choosing an exercise and logging it, shown
/// only when that exercise actually has variants — an exercise without
/// them never sees this and dismisses straight through, which is what
/// keeps the common path unchanged.
///
/// `suggested` is the variant used most recently for this exercise,
/// pre-selected on the way in. In practice you repeat the same variant
/// session to session, so the default is usually already right and this
/// collapses to a single confirming tap.
struct VariantPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise
    let suggested: ExerciseVariant?
    let onSelect: (ExerciseVariant?) -> Void

    @State private var selection: ExerciseVariant?

    init(
        exercise: Exercise,
        suggested: ExerciseVariant?,
        onSelect: @escaping (ExerciseVariant?) -> Void
    ) {
        self.exercise = exercise
        self.suggested = suggested
        self.onSelect = onSelect
        _selection = State(initialValue: suggested)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(exercise.sortedVariants) { variant in
                        row(
                            title: variant.name,
                            detail: detail(for: variant),
                            isSelected: selection?.persistentModelID == variant.persistentModelID
                        ) {
                            selection = variant
                        }
                    }
                } header: {
                    Text("How are you doing it?")
                }

                Section {
                    row(
                        title: "Not specified",
                        detail: nil,
                        isSelected: selection == nil
                    ) {
                        selection = nil
                    }
                } footer: {
                    Text("Each variation keeps its own history, records, and previous-set reference.")
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSelect(selection)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    /// Surfaces what actually differs about a variant, so the choice can
    /// be made without remembering what each one was configured to do —
    /// its muscles when it retargets, and its format when it changes how
    /// the movement is logged.
    private func detail(for variant: ExerciseVariant) -> String? {
        var parts: [String] = []

        if !variant.primaryMuscleTargets.isEmpty {
            parts.append(variant.primaryMuscleTargets.map(\.displayName).joined(separator: ", "))
        }
        if let type = variant.loggingType {
            parts.append(type.rawValue)
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func row(
        title: String,
        detail: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
