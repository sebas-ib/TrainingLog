//
//  WorkoutDetailView.swift
//  workout-tracker
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
        List {
            Section {
                WorkoutSummaryView(session: session)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            
            if session.exercises.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "dumbbell.fill",
                        description: Text("Tap 'Add Exercise' below to start tracking your movements.")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(session.exercises) { workoutExercise in
                    Section {
                        ExerciseSetsView(workoutExercise: workoutExercise, focusedField: $focusedField)
                    } header: {
                        HStack {
                            NavigationLink {
                                ExerciseProgressView(exercise: workoutExercise.exercise)
                            } label: {
                                Text(workoutExercise.exercise.name)
                                    .font(.headline)
                                    .textCase(nil)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                exercisePendingDeletion = workoutExercise
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            
            Section {
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } footer: {
                Spacer()
                    .frame(height: 60)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(session.name ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    renameText = session.name ?? ""
                    showingRenameAlert = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { selectedExercise in
                addExercise(selectedExercise)
            }
        }
        .alert("Rename Session", isPresented: $showingRenameAlert) {
            TextField("Session Name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                session.name = renameText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : renameText
                try? modelContext.save()
            }
        } message: {
            Text("Give this session a name, like 'Push Day' or 'Leg Day.'")
        }
        .alert(
            "Delete \(exercisePendingDeletion?.exercise.name ?? "Exercise")?",
            isPresented: Binding(
                get: { exercisePendingDeletion != nil },
                set: { if !$0 { exercisePendingDeletion = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) {
                exercisePendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                if let exercise = exercisePendingDeletion {
                    deleteExercise(exercise)
                }
                exercisePendingDeletion = nil
            }
        } message: {
            Text("This will permanently remove this exercise and all of its logged sets from this session.")
        }
        .highPriorityGesture(
            TapGesture().onEnded {
                focusedField = nil
            },
            including: focusedField != nil ? .all : .none
        )
    }
        
    private func addExercise(_ exercise: Exercise) {
        let workoutExercise = WorkoutExercise(exercise: exercise, loggedAt: session.startTime)
        session.exercises.append(workoutExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save newly added exercise: \(error.localizedDescription)")
        }
    }
    
    private func deleteExercise(_ workoutExercise: WorkoutExercise) {
        session.exercises.removeAll { $0.persistentModelID == workoutExercise.persistentModelID }
        modelContext.delete(workoutExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save deletion context updates: \(error.localizedDescription)")
        }
    }
}
