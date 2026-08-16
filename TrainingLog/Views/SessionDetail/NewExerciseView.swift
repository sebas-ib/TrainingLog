//
//  NewExerciseView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//


import SwiftUI
import SwiftData

struct NewExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let name: String
    let onCreate: (Exercise) -> Void
    
    @State private var loggingType: ExerciseLoggingType = .weightReps
    @State private var primaryGroup: MuscleGroup = .other
    @State private var secondaryGroup: MuscleGroup?
    @State private var includeSecondary = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    Text(name)
                        .font(.headline)
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
                
                Section("Primary Muscle Group") {
                    Picker("Primary", selection: $primaryGroup) {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section {
                    Toggle("Also targets a secondary muscle", isOn: $includeSecondary.animation())
                    
                    if includeSecondary {
                        Picker("Secondary", selection: Binding(
                            get: { secondaryGroup ?? .other },
                            set: { secondaryGroup = $0 }
                        )) {
                            ForEach(MuscleGroup.allCases.filter { $0 != primaryGroup }, id: \.self) { group in
                                Text(group.rawValue).tag(group)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        createExercise()
                    }
                }
            }
        }
    }
    
    private func createExercise() {
        let exercise = Exercise(
            name: name,
            isCustom: true,
            muscleGroup: primaryGroup,
            secondaryMuscleGroup: includeSecondary ? secondaryGroup : nil,
            loggingType: loggingType
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        onCreate(exercise)
    }
}
