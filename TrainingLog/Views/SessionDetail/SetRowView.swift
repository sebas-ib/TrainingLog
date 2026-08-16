//
//  SetRowView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

enum SetField: Hashable {
    case reps(PersistentIdentifier)
    case weight(PersistentIdentifier)
    case bodyWeightModifier(PersistentIdentifier)
    case durationMinutes(PersistentIdentifier)
    case durationSeconds(PersistentIdentifier)
    case distance(PersistentIdentifier)
}

struct SetRowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    @Bindable var set: ExerciseSet
    let loggingType: ExerciseLoggingType
    var focusedField: FocusState<SetField?>.Binding
    var previousSet: ExerciseSet?
    
    private var displayWeight: Binding<Double> {
        Binding(
            get: { unitSettings.unit.convert(fromLbs: set.weight) },
            set: { newValue in
                set.weight = unitSettings.unit.convertToLbs(newValue)
                try? modelContext.save()
            }
        )
    }
    
    private var displayBodyWeightModifier: Binding<Double> {
        Binding(
            get: { unitSettings.unit.convert(fromLbs: set.bodyWeightModifier) },
            set: { newValue in
                set.bodyWeightModifier = unitSettings.unit.convertToLbs(newValue)
                try? modelContext.save()
            }
        )
    }
    
    private var durationMinutes: Binding<Int> {
        Binding(
            get: { set.durationSeconds / 60 },
            set: { newValue in
                let seconds = set.durationSeconds % 60
                set.durationSeconds = newValue * 60 + seconds
                try? modelContext.save()
            }
        )
    }
    
    private var durationSecondsOnly: Binding<Int> {
        Binding(
            get: { set.durationSeconds % 60 },
            set: { newValue in
                let minutes = set.durationSeconds / 60
                set.durationSeconds = minutes * 60 + newValue
                try? modelContext.save()
            }
        )
    }
    
    private var previousHint: String? {
        guard let previousSet else { return nil }
        var parts: [String] = []
        
        switch loggingType {
        case .weightReps:
            let w = unitSettings.unit.convert(fromLbs: previousSet.weight)
            parts.append("\(previousSet.reps) × \(String(format: "%.0f", w)) \(unitSettings.unit.rawValue)")
        case .bodyweightReps:
            parts.append("\(previousSet.reps) reps")
            if previousSet.bodyWeightModifier != 0 {
                let mod = unitSettings.unit.convert(fromLbs: previousSet.bodyWeightModifier)
                parts.append(mod > 0 ? "+\(String(format: "%.0f", mod)) \(unitSettings.unit.rawValue)" : "\(String(format: "%.0f", mod)) \(unitSettings.unit.rawValue)")
            }
        case .time:
            parts.append(formattedDuration(previousSet.durationSeconds))
        case .timeWeight:
            let w = unitSettings.unit.convert(fromLbs: previousSet.weight)
            parts.append("\(formattedDuration(previousSet.durationSeconds)) @ \(String(format: "%.0f", w)) \(unitSettings.unit.rawValue)")
        case .distanceTime:
            parts.append("\(String(format: "%.2f", previousSet.distance)) mi in \(formattedDuration(previousSet.durationSeconds))")
        case .repsOnly:
            parts.append("\(previousSet.reps) reps")
        }
        
        if previousSet.takenToFailure {
            parts.append("Failure")
        }
        
        return "Last: " + parts.joined(separator: " · ")
    }
    
    private func formattedDuration(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Set \(set.order)")
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
                
                fieldsForType
                
                Spacer()
                
                Button {
                    set.takenToFailure.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: set.takenToFailure ? "flame.fill" : "flame")
                        .foregroundStyle(set.takenToFailure ? .orange : .secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(set.takenToFailure ? "Taken to failure" : "Not taken to failure")
            }
            
            if let previousHint {
                Text(previousHint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 50)
            }
        }
        .onChange(of: set.reps) { _, _ in try? modelContext.save() }
    }
    
    @ViewBuilder
    private var fieldsForType: some View {
        switch loggingType {
        case .weightReps:
            TextField("Reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 55)
                .focused(focusedField, equals: .reps(set.persistentModelID))
            Text("×")
                .foregroundStyle(.secondary)
            TextField("Weight", value: displayWeight, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 65)
                .focused(focusedField, equals: .weight(set.persistentModelID))
            Text(unitSettings.unit.rawValue)
                .foregroundStyle(.secondary)
            
        case .bodyweightReps:
            TextField("Reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 55)
                .focused(focusedField, equals: .reps(set.persistentModelID))
            Text("reps")
                .foregroundStyle(.secondary)
            TextField("+/-", value: displayBodyWeightModifier, format: .number)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .focused(focusedField, equals: .bodyWeightModifier(set.persistentModelID))
            Text(unitSettings.unit.rawValue)
                .foregroundStyle(.secondary)
            
        case .time:
            TextField("Min", value: durationMinutes, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 45)
                .focused(focusedField, equals: .durationMinutes(set.persistentModelID))
            Text(":")
            TextField("Sec", value: durationSecondsOnly, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 45)
                .focused(focusedField, equals: .durationSeconds(set.persistentModelID))
            
        case .timeWeight:
            TextField("Min", value: durationMinutes, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 40)
                .focused(focusedField, equals: .durationMinutes(set.persistentModelID))
            Text(":")
            TextField("Sec", value: durationSecondsOnly, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 40)
                .focused(focusedField, equals: .durationSeconds(set.persistentModelID))
            TextField("Weight", value: displayWeight, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 55)
                .focused(focusedField, equals: .weight(set.persistentModelID))
            Text(unitSettings.unit.rawValue)
                .foregroundStyle(.secondary)
            
        case .distanceTime:
            TextField("Miles", value: $set.distance, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 55)
                .focused(focusedField, equals: .distance(set.persistentModelID))
            Text("mi in")
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField("Min", value: durationMinutes, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 40)
                .focused(focusedField, equals: .durationMinutes(set.persistentModelID))
            Text(":")
            TextField("Sec", value: durationSecondsOnly, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 40)
                .focused(focusedField, equals: .durationSeconds(set.persistentModelID))
            
        case .repsOnly:
            TextField("Reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .focused(focusedField, equals: .reps(set.persistentModelID))
            Text("reps")
                .foregroundStyle(.secondary)
        }
    }
}
