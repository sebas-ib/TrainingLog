//
//  WorkoutDetailView.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: WorkoutSession

    @State private var showingExercisePicker = false
    @State private var exercisePendingDeletion: WorkoutExercise?

    @State private var showingRenameAlert = false
    @State private var renameText = ""

    @FocusState private var focusedField: SetField?

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                // MARK: - Workout Summary

                Section {
                    WorkoutSummaryView(session: session)
                        .listRowInsets(
                            EdgeInsets(
                                top: 8,
                                leading: 0,
                                bottom: 8,
                                trailing: 0
                            )
                        )
                        .listRowBackground(Color.clear)
                }

                // MARK: - Exercises

                if session.exercises.isEmpty {
                    emptyWorkoutSection
                } else {
                    ForEach(session.exercises) { workoutExercise in
                        exerciseSection(for: workoutExercise)
                    }
                }

                // Extra bottom space so the final exercise isn't
                // hidden behind the bottom action.
                Section {
                    Color.clear
                        .frame(height: 70)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(session.name ?? "Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    renameButton
                }
            }

            // Floats above the List, outside its layout system,
            // so keyboard avoidance can't push it around.
            addExerciseButton
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { selectedExercise in
                addExercise(selectedExercise)
            }
        }
        .alert(
            "Rename Session",
            isPresented: $showingRenameAlert
        ) {
            TextField(
                "Session Name",
                text: $renameText
            )

            Button("Cancel", role: .cancel) {
                renameText = ""
            }

            Button("Save") {
                renameSession()
            }
        } message: {
            Text(
                "Give this session a name, like \"Push Day\" or \"Leg Day.\""
            )
        }
        .alert(
            "Delete \(exercisePendingDeletion?.exercise.name ?? "Exercise")?",
            isPresented: deletionAlertBinding
        ) {
            Button("Cancel", role: .cancel) {
                exercisePendingDeletion = nil
            }

            Button("Delete", role: .destructive) {
                confirmDeleteExercise()
            }
        } message: {
            Text(
                "This will permanently remove this exercise and all of its logged sets from this session."
            )
        }
    }

    // MARK: - Exercise Section

    @ViewBuilder
    private func exerciseSection(
        for workoutExercise: WorkoutExercise
    ) -> some View {
        Section {
            ExerciseSetsView(
                workoutExercise: workoutExercise,
                focusedField: $focusedField
            )
            .listRowInsets(
                EdgeInsets(
                    top: 4,
                    leading: 12,
                    bottom: 8,
                    trailing: 12
                )
            )
        } header: {
            exerciseHeader(for: workoutExercise)
        }
    }

    // MARK: - Exercise Header

    private func exerciseHeader(
        for workoutExercise: WorkoutExercise
    ) -> some View {
        HStack(spacing: 10) {
            NavigationLink {
                ExerciseProgressView(
                    exercise: workoutExercise.exercise
                )
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "dumbbell.fill")
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(Theme.accent)
                        .frame(
                            width: 30,
                            height: 30
                        )
                        .background(
                            Circle()
                                .fill(
                                    Theme.accent.opacity(0.12)
                                )
                        )

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {
                        Text(workoutExercise.exercise.name)
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.primary)
                            .textCase(nil)

                        Text("View progress")
                            .font(
                                .system(
                                    size: 11,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(
                            .system(
                                size: 11,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            deleteExerciseButton(
                for: workoutExercise
            )
        }
        .padding(.vertical, 4)
        .textCase(nil)
    }

    // MARK: - Delete Exercise Button

    private func deleteExerciseButton(
        for workoutExercise: WorkoutExercise
    ) -> some View {
        Button(role: .destructive) {
            focusedField = nil

            let generator =
                UIImpactFeedbackGenerator(
                    style: .light
                )
            generator.impactOccurred()

            exercisePendingDeletion = workoutExercise
        } label: {
            Image(systemName: "trash")
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)
                .frame(
                    width: 32,
                    height: 32
                )
                .background(
                    Circle()
                        .fill(
                            Color(.secondarySystemBackground)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Delete \(workoutExercise.exercise.name)"
        )
    }

    // MARK: - Empty Workout

    private var emptyWorkoutSection: some View {
        Section {
            VStack(spacing: 14) {
                Image(systemName: "dumbbell.fill")
                    .font(
                        .system(
                            size: 30,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(Theme.accent)
                    .frame(
                        width: 64,
                        height: 64
                    )
                    .background(
                        Circle()
                            .fill(
                                Theme.accent.opacity(0.12)
                            )
                    )

                VStack(spacing: 5) {
                    Text("No Exercises")
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )

                    Text(
                        "Add an exercise to start tracking your workout."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }

                Button {
                    showingExercisePicker = true
                } label: {
                    Label(
                        "Add Exercise",
                        systemImage: "plus"
                    )
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Theme.accent)
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(
                maxWidth: .infinity
            )
            .padding(.vertical, 32)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - Add Exercise

    private var addExerciseButton: some View {
        Button {
            focusedField = nil

            let generator =
                UIImpactFeedbackGenerator(
                    style: .light
                )
            generator.impactOccurred()

            showingExercisePicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )

                Text("Add Exercise")
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
            }
            .foregroundStyle(.white)
            .frame(
                maxWidth: .infinity
            )
            .frame(height: 50)
            .background(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(Theme.accent)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Rename

    private var renameButton: some View {
        Button {
            renameText = session.name ?? ""
            showingRenameAlert = true
        } label: {
            Image(systemName: "pencil")
        }
        .accessibilityLabel("Rename workout")
    }

    private func renameSession() {
        let trimmedName =
            renameText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        session.name =
            trimmedName.isEmpty
            ? nil
            : trimmedName

        try? modelContext.save()

        renameText = ""
    }

    // MARK: - Deletion Alert

    private var deletionAlertBinding: Binding<Bool> {
        Binding(
            get: {
                exercisePendingDeletion != nil
            },
            set: { isPresented in
                if !isPresented {
                    exercisePendingDeletion = nil
                }
            }
        )
    }

    private func confirmDeleteExercise() {
        guard let workoutExercise =
            exercisePendingDeletion
        else {
            return
        }

        deleteExercise(workoutExercise)

        exercisePendingDeletion = nil
    }

    // MARK: - Add Exercise

    private func addExercise(
        _ exercise: Exercise
    ) {
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            loggedAt: session.startTime
        )

        withAnimation(
            .spring(
                response: 0.4,
                dampingFraction: 0.8
            )
        ) {
            session.exercises.append(
                workoutExercise
            )
        }

        do {
            try modelContext.save()
        } catch {
            print(
                "Failed to save newly added exercise: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Delete Exercise

    private func deleteExercise(
        _ workoutExercise: WorkoutExercise
    ) {
        withAnimation(
            .spring(
                response: 0.35,
                dampingFraction: 0.8
            )
        ) {
            session.exercises.removeAll {
                $0.persistentModelID ==
                    workoutExercise.persistentModelID
            }

            modelContext.delete(
                workoutExercise
            )
        }

        do {
            try modelContext.save()
        } catch {
            print(
                "Failed to save deletion context updates: \(error.localizedDescription)"
            )
        }
    }
}
