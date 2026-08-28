//
//  VariantFormView.swift
//  TrainingLog
//

import SwiftUI

/// Creates or edits one variant of an exercise.
///
/// Every field here is an override with an explicit "inherit" state,
/// which is what lets one form cover all three kinds of variant: one
/// that retargets the movement, one that changes how it's logged, and
/// one that overrides nothing and exists purely to keep its own history.
struct VariantFormView: View {
    @Environment(\.dismiss) private var dismiss

    let parent: Exercise
    private let existing: ExerciseVariant?
    private let onSave: (VariantDraft) -> Void

    @State private var name: String
    @State private var primaryTargets: Set<MuscleTarget>
    @State private var secondaryTargets: Set<MuscleTarget>
    @State private var overridesLoggingType: Bool
    @State private var loggingType: ExerciseLoggingType

    /// What the form hands back — a plain value, so the caller decides
    /// whether it becomes a new variant or an edit to an existing one,
    /// and nothing is written to the store until the parent form saves.
    struct VariantDraft {
        var name: String
        var primaryTargets: [MuscleTarget]
        var secondaryTargets: [MuscleTarget]
        var loggingType: ExerciseLoggingType?
    }

    init(parent: Exercise, editing variant: ExerciseVariant? = nil, onSave: @escaping (VariantDraft) -> Void) {
        self.parent = parent
        self.existing = variant
        self.onSave = onSave
        _name = State(initialValue: variant?.name ?? "")
        _primaryTargets = State(initialValue: Set(variant?.primaryMuscleTargets ?? []))
        _secondaryTargets = State(initialValue: Set(variant?.secondaryMuscleTargets ?? []))
        _overridesLoggingType = State(initialValue: variant?.loggingType != nil)
        _loggingType = State(initialValue: variant?.loggingType ?? parent.loggingType)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var overridesTargets: Bool {
        !primaryTargets.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. High Foot, Wide Grip", text: $name)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Shown as \"\(parent.name) · \(name.isEmpty ? "…" : name)\".")
                }

                Section {
                    NavigationLink {
                        MuscleTargetPickerView(
                            title: "Primary Muscles",
                            excluding: secondaryTargets,
                            selection: $primaryTargets
                        )
                    } label: {
                        targetRow(title: "Primary", targets: primaryTargets, inherited: parent.primaryMuscleTargets)
                    }

                    NavigationLink {
                        MuscleTargetPickerView(
                            title: "Secondary Muscles",
                            excluding: primaryTargets,
                            selection: $secondaryTargets
                        )
                    } label: {
                        targetRow(title: "Secondary", targets: secondaryTargets, inherited: parent.secondaryMuscleTargets)
                    }
                } header: {
                    Text("Muscles Targeted")
                } footer: {
                    Text(
                        overridesTargets
                        ? "This variation replaces the exercise's muscles rather than adding to them."
                        : "Leave empty to use the exercise's own muscles."
                    )
                }

                Section {
                    Toggle("Log differently", isOn: $overridesLoggingType.animation())

                    if overridesLoggingType {
                        Picker("Type", selection: $loggingType) {
                            ForEach(ExerciseLoggingType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                } header: {
                    Text("How is this tracked?")
                } footer: {
                    Text(
                        overridesLoggingType
                        ? "Sets logged for this variation use these fields instead of the exercise's."
                        : "Uses the exercise's setting: \(parent.loggingType.rawValue)."
                    )
                }
            }
            .navigationTitle(existing == nil ? "New Variation" : "Edit Variation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(
                            VariantDraft(
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                primaryTargets: ordered(primaryTargets),
                                secondaryTargets: ordered(secondaryTargets),
                                loggingType: overridesLoggingType ? loggingType : nil
                            )
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func targetRow(title: String, targets: Set<MuscleTarget>, inherited: [MuscleTarget]) -> some View {
        HStack {
            Text(title)
            Spacer()
            if targets.isEmpty {
                Text(inherited.isEmpty ? "None" : "Inherited")
                    .foregroundStyle(.secondary)
            } else {
                Text(ordered(targets).map(\.displayName).joined(separator: ", "))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    /// Same canonical ordering the exercise form uses — `Set` iteration
    /// order isn't stable across launches, and the first primary target
    /// decides the muscle group.
    private func ordered(_ targets: Set<MuscleTarget>) -> [MuscleTarget] {
        MuscleTarget.allCases.filter(targets.contains)
    }
}
