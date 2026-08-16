//
//  WorkoutListView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//

import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings

    let workoutDay: WorkoutDay
    let onWorkoutSessionCreated: (WorkoutSession) -> Void

    @State private var workoutSessionPendingDeletion: WorkoutSession?
    @State private var showingNewWorkoutSheet = false
    @State private var saveError: Error?

    private var sortedWorkouts: [WorkoutSession] {
        workoutDay.sessions.sorted {
            $0.startTime < $1.startTime
        }
    }

    var body: some View {
        Section {
            ForEach(sortedWorkouts) { workout in
                WorkoutRow(
                    workout: workout,
                    onDelete: {
                        workoutSessionPendingDeletion = workout
                    }
                )
            }

            addWorkoutButton

        } header: {
            Text("Workouts")
                .font(Theme.sectionHeader())
                .foregroundStyle(.secondary)
        }
        .alert(
            "Delete \(workoutSessionPendingDeletion?.name ?? "Workout")?",
            isPresented: deletionAlertBinding
        ) {
            Button("Cancel", role: .cancel) {
                workoutSessionPendingDeletion = nil
            }

            Button("Delete", role: .destructive) {
                deletePendingWorkout()
            }
        } message: {
            Text(
                "This will permanently remove this workout and all logged exercises and sets within it."
            )
        }
        .alert(
            "Couldn't Save Changes",
            isPresented: saveErrorBinding
        ) {
            Button("OK", role: .cancel) {
                saveError = nil
            }
        } message: {
            Text(
                saveError?.localizedDescription
                ?? "An unknown error occurred while saving your workout."
            )
        }
        .sheet(isPresented: $showingNewWorkoutSheet) {
            NewWorkoutSessionView(targetDate: workoutDay.date) { newWorkout in
                workoutDay.sessions.append(newWorkout)
                saveChanges()
                onWorkoutSessionCreated(newWorkout)
            }
            .tint(Theme.accent)
        }
    }

    private var addWorkoutButton: some View {
        Button {
            showingNewWorkoutSheet = true
        } label: {
            Label("Add Another Workout", systemImage: "plus")
                .font(
                    .system(
                        .body,
                        design: .rounded,
                        weight: .semibold
                    )
                )
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Theme.accent)
        .padding(.horizontal)
    }

    private var deletionAlertBinding: Binding<Bool> {
        Binding(
            get: {
                workoutSessionPendingDeletion != nil
            },
            set: { isPresented in
                if !isPresented {
                    workoutSessionPendingDeletion = nil
                }
            }
        )
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: {
                saveError != nil
            },
            set: { isPresented in
                if !isPresented {
                    saveError = nil
                }
            }
        )
    }

    private func deletePendingWorkout() {
        guard let workout = workoutSessionPendingDeletion else {
            return
        }

        withAnimation(
            .spring(
                response: 0.45,
                dampingFraction: 0.85
            )
        ) {
            workoutDay.sessions.removeAll {
                $0.persistentModelID == workout.persistentModelID
            }

            modelContext.delete(workout)
            workoutSessionPendingDeletion = nil
        }

        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            saveError = error
        }
    }
}

// MARK: - Workout Row

private struct WorkoutRow: View {
    @EnvironmentObject private var unitSettings: UnitSettings

    let workout: WorkoutSession
    let onDelete: () -> Void

    private var volumes: [(group: MuscleGroup, volume: Double)] {
        WorkoutCalculations.volumeByMuscleGroup(for: workout)
            .map {
                (
                    group: $0.key,
                    volume: $0.value
                )
            }
            .sorted {
                $0.volume > $1.volume
            }
    }

    var body: some View {
        NavigationLink {
            WorkoutDetailView(session: workout)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                workoutName
                workoutTime
                muscleGroupVolumes
            }
            .padding(.vertical, 4)
        }
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {
            Button {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }

    private var workoutName: some View {
        Text(workout.name ?? "Workout")
            .font(.headline)
    }

    private var workoutTime: some View {
        Text(workout.startTime, style: .time)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var muscleGroupVolumes: some View {
        if !volumes.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(volumes.prefix(3), id: \.group) { entry in
                    MuscleVolumeBadge(
                        group: entry.group,
                        volume: entry.volume,
                        unit: unitSettings.unit
                    )
                }
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - Muscle Volume Badge

private struct MuscleVolumeBadge: View {
    let group: MuscleGroup
    let volume: Double
    let unit: WeightUnit

    private var convertedVolume: Int {
        Int(unit.convert(fromLbs: volume))
    }

    private var text: String {
        "\(group.rawValue): \(convertedVolume)\(unit.rawValue)"
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                Theme.accent.opacity(0.12)
            )
            .clipShape(Capsule())
    }
}
