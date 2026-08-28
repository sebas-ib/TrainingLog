//
//  ExerciseFormView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//

import SwiftUI
import SwiftData

/// Creates a brand-new exercise, or edits an existing one — same form
/// either way, since the fields (name, how it's tracked, which muscles
/// it targets) don't differ between the two; only what happens on save
/// does.
struct ExerciseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingExercise: Exercise?
    private let onSave: (Exercise) -> Void

    @State private var name: String
    @State private var loggingType: ExerciseLoggingType
    @State private var primaryTargets: Set<MuscleTarget>
    @State private var secondaryTargets: Set<MuscleTarget>
    @State private var saveError: Error?

    /// Creation mode — `name` seeds the field from whatever the user
    /// searched for, but stays editable in case they want to tweak it
    /// before saving.
    init(name: String, onCreate: @escaping (Exercise) -> Void) {
        self.existingExercise = nil
        self.onSave = onCreate
        _name = State(initialValue: name)
        _loggingType = State(initialValue: .weightReps)
        _primaryTargets = State(initialValue: [])
        _secondaryTargets = State(initialValue: [])
    }

    /// Edit mode — every field starts populated from `exercise`.
    init(editing exercise: Exercise, onSave: @escaping (Exercise) -> Void) {
        self.existingExercise = exercise
        self.onSave = onSave
        _name = State(initialValue: exercise.name)
        _loggingType = State(initialValue: exercise.loggingType)
        _primaryTargets = State(initialValue: Set(exercise.primaryMuscleTargets))
        _secondaryTargets = State(initialValue: Set(exercise.secondaryMuscleTargets))
    }

    private var isEditing: Bool {
        existingExercise != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise Name", text: $name)
                }

                Section("How is this tracked?") {
                    Picker("Type", selection: $loggingType) {
                        ForEach(ExerciseLoggingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    NavigationLink {
                        MuscleTargetPickerView(
                            title: "Primary Muscles",
                            excluding: secondaryTargets,
                            selection: $primaryTargets
                        )
                    } label: {
                        muscleTargetRow(title: "Primary", targets: primaryTargets)
                    }

                    NavigationLink {
                        MuscleTargetPickerView(
                            title: "Secondary Muscles",
                            excluding: primaryTargets,
                            selection: $secondaryTargets
                        )
                    } label: {
                        muscleTargetRow(title: "Secondary", targets: secondaryTargets)
                    }
                } header: {
                    Text("Muscles Targeted")
                } footer: {
                    Text("Used to group this exercise on the Progress tab and to break down training volume by muscle.")
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .saveErrorAlert($saveError)
        }
    }

    private func muscleTargetRow(title: String, targets: Set<MuscleTarget>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(summary(for: targets))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func summary(for targets: Set<MuscleTarget>) -> String {
        guard !targets.isEmpty else { return "None" }
        return targets.map(\.displayName).sorted().joined(separator: ", ")
    }

    /// Puts a selection back into `MuscleTarget`'s own declaration order —
    /// the same order the picker lists them in. `Set` iteration order isn't
    /// stable across launches, and `setMuscleTargets` derives the broad
    /// `muscleGroup` from the *first* element, so converting with a plain
    /// `Array(...)` meant saving the same selection twice could pick a
    /// different group each time — and with it a different Progress-tab
    /// section, row icon, and volume-by-muscle-group bucket.
    private func ordered(_ targets: Set<MuscleTarget>) -> [MuscleTarget] {
        MuscleTarget.allCases.filter(targets.contains)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let primary = ordered(primaryTargets)
        let secondary = ordered(secondaryTargets)

        let saved: Exercise

        if let existingExercise {
            existingExercise.name = trimmedName
            existingExercise.loggingType = loggingType
            existingExercise.setMuscleTargets(primary: primary, secondary: secondary)
            saved = existingExercise
        } else {
            let exercise = Exercise(
                name: trimmedName,
                isCustom: true,
                primaryMuscleTargets: primary,
                secondaryMuscleTargets: secondary,
                loggingType: loggingType
            )
            modelContext.insert(exercise)
            saved = exercise
        }

        modelContext.save(reportingTo: $saveError)

        // Stay open on a failed write so the alert is actually visible
        // and the user's entries aren't thrown away — dismissing here
        // would tear down the sheet the alert is attached to.
        guard saveError == nil else { return }

        onSave(saved)
        dismiss()
    }
}
