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

    @Query private var allWorkoutExercises: [WorkoutExercise]
    @State private var variantBeingEdited: ExerciseVariant?
    @State private var showingNewVariantSheet = false
    @State private var variantBlockedFromDeletion: ExerciseVariant?

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

                variantsSection
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
            .sheet(isPresented: $showingNewVariantSheet) {
                if let existingExercise {
                    VariantFormView(parent: existingExercise) { draft in
                        addVariant(draft)
                    }
                }
            }
            .sheet(item: $variantBeingEdited) { variant in
                if let existingExercise {
                    VariantFormView(parent: existingExercise, editing: variant) { draft in
                        apply(draft, to: variant)
                    }
                }
            }
            .alert(
                "Can't Delete \(variantBlockedFromDeletion?.name ?? "Variation")",
                isPresented: Binding(
                    get: { variantBlockedFromDeletion != nil },
                    set: { if !$0 { variantBlockedFromDeletion = nil } }
                )
            ) {
                Button("OK", role: .cancel) { variantBlockedFromDeletion = nil }
            } message: {
                Text("This variation has logged history, so it can't be deleted. Edit it instead if you want to change its name or muscles.")
            }
        }
    }

    // MARK: - Variations

    /// Only offered when editing an existing exercise: a variant has to
    /// hang off a saved parent, and buffering drafts through creation
    /// would add a whole staging layer for a rare case — a brand-new
    /// custom exercise can be reopened to add variations straight after.
    ///
    /// Unlike the fields above (which apply on Save), variant edits
    /// commit as they're made, so this section behaves like a
    /// self-contained sub-editor rather than something Cancel unwinds.
    @ViewBuilder
    private var variantsSection: some View {
        if let existingExercise {
            Section {
                ForEach(existingExercise.sortedVariants) { variant in
                    Button {
                        variantBeingEdited = variant
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(variant.name)
                                    .foregroundStyle(.primary)
                                if let detail = detail(for: variant) {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            requestDeleteVariant(variant)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Button {
                    showingNewVariantSheet = true
                } label: {
                    Label("Add Variation", systemImage: "plus.circle")
                }
            } header: {
                Text("Variations")
            } footer: {
                Text("Different ways to do this movement — a grip, stance, or foot position. Each keeps its own history and records.")
            }
        }
    }

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

    private func variantHasHistory(_ variant: ExerciseVariant) -> Bool {
        allWorkoutExercises.contains {
            $0.variant?.persistentModelID == variant.persistentModelID
        }
    }

    /// Mirrors how deleting an exercise with logged history is handled —
    /// blocked rather than silently orphaning the sets that reference it.
    private func requestDeleteVariant(_ variant: ExerciseVariant) {
        guard !variantHasHistory(variant) else {
            variantBlockedFromDeletion = variant
            return
        }

        existingExercise?.variants.removeAll {
            $0.persistentModelID == variant.persistentModelID
        }
        modelContext.delete(variant)
        modelContext.save(reportingTo: $saveError)
    }

    private func addVariant(_ draft: VariantFormView.VariantDraft) {
        guard let existingExercise else { return }

        let nextOrder = (existingExercise.variants.map(\.order).max() ?? 0) + 1
        let variant = ExerciseVariant(
            name: draft.name,
            order: nextOrder,
            isCustom: true,
            primaryMuscleTargets: draft.primaryTargets,
            secondaryMuscleTargets: draft.secondaryTargets,
            loggingType: draft.loggingType
        )

        modelContext.insert(variant)
        existingExercise.variants.append(variant)
        modelContext.save(reportingTo: $saveError)
    }

    private func apply(_ draft: VariantFormView.VariantDraft, to variant: ExerciseVariant) {
        variant.name = draft.name
        variant.primaryMuscleTargets = draft.primaryTargets
        variant.secondaryMuscleTargets = draft.secondaryTargets
        variant.loggingType = draft.loggingType
        modelContext.save(reportingTo: $saveError)
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
