//
//  ExerciseProgressView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData
import Charts

struct ExerciseProgressView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    @Bindable var exercise: Exercise

    @Query(sort: \WorkoutExercise.loggedAt, order: .forward) private var allWorkoutExercises: [WorkoutExercise]

    @State private var showingEditSheet = false

    private var muscleTargetsSummary: String? {
        guard !exercise.primaryMuscleTargets.isEmpty else { return nil }
        var text = exercise.primaryMuscleTargets.map(\.rawValue).joined(separator: ", ")
        if !exercise.secondaryMuscleTargets.isEmpty {
            text += " · also " + exercise.secondaryMuscleTargets.map(\.rawValue).joined(separator: ", ")
        }
        return text
    }

    private var loggingType: ExerciseLoggingType {
        exercise.loggingType
    }
    
    private enum Metric: String, CaseIterable {
        case primary
        case secondary
        
        func label(for type: ExerciseLoggingType) -> String {
            switch type {
            case .weightReps: return self == .primary ? "Max Weight" : "Volume"
            case .bodyweightReps: return self == .primary ? "Max Reps" : "Weight Modifier"
            case .time: return "Duration"
            case .timeWeight: return self == .primary ? "Duration" : "Weight"
            case .distanceTime: return self == .primary ? "Distance" : "Pace"
            case .repsOnly: return "Max Reps"
            }
        }
    }
    
    private var availableMetrics: [Metric] {
        switch loggingType {
        case .weightReps, .bodyweightReps, .timeWeight, .distanceTime:
            return [.primary, .secondary]
        case .time, .repsOnly:
            return [.primary]
        }
    }
    
    @State private var selectedMetric: Metric = .primary
    
    private var history: [WorkoutExercise] {
        allWorkoutExercises.filter { $0.exercise.persistentModelID == exercise.persistentModelID }
    }
    
    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    private var unitLabel: String {
        switch loggingType {
        case .weightReps, .timeWeight:
            return selectedMetric == .primary && loggingType == .timeWeight ? "sec" : unitSettings.unit.rawValue
        case .bodyweightReps:
            return selectedMetric == .primary ? "reps" : unitSettings.unit.rawValue
        case .time:
            return "sec"
        case .distanceTime:
            return selectedMetric == .primary
                ? unitSettings.distanceUnit.rawValue
                : "min/\(unitSettings.distanceUnit.rawValue)"
        case .repsOnly:
            return "reps"
        }
    }
    
    private var dataPoints: [DataPoint] {
        history.compactMap { instance in
            guard let value = metricValue(for: instance) else { return nil }
            return DataPoint(date: instance.loggedAt, value: value)
        }
    }
    
    private func metricValue(for instance: WorkoutExercise) -> Double? {
        switch loggingType {
        case .weightReps:
            if selectedMetric == .primary {
                guard let maxWeight = instance.sets.map(\.weight).max(), maxWeight > 0 else { return nil }
                return unitSettings.unit.convert(fromLbs: maxWeight)
            } else {
                let volume = WorkoutCalculations.volume(for: instance)
                guard volume > 0 else { return nil }
                return unitSettings.unit.convert(fromLbs: volume)
            }
            
        case .bodyweightReps:
            if selectedMetric == .primary {
                guard let maxReps = instance.sets.map(\.reps).max(), maxReps > 0 else { return nil }
                return Double(maxReps)
            } else {
                guard let modifier = instance.sets.map(\.bodyWeightModifier).max(by: { abs($0) < abs($1) }) else { return nil }
                return unitSettings.unit.convert(fromLbs: modifier)
            }
            
        case .time:
            guard let maxDuration = instance.sets.map(\.durationSeconds).max(), maxDuration > 0 else { return nil }
            return Double(maxDuration)
            
        case .timeWeight:
            if selectedMetric == .primary {
                guard let maxDuration = instance.sets.map(\.durationSeconds).max(), maxDuration > 0 else { return nil }
                return Double(maxDuration)
            } else {
                guard let maxWeight = instance.sets.map(\.weight).max(), maxWeight > 0 else { return nil }
                return unitSettings.unit.convert(fromLbs: maxWeight)
            }
            
        case .distanceTime:
            if selectedMetric == .primary {
                guard let maxDistance = instance.sets.map(\.distance).max(), maxDistance > 0 else { return nil }
                return unitSettings.distanceUnit.convert(fromMiles: maxDistance)
            } else {
                // Pace = minutes per distance unit, using the best
                // (fastest) set. Converting distance to the display unit
                // before dividing keeps this correct in both mi and km,
                // rather than always computing a per-mile pace.
                let paces: [Double] = instance.sets.compactMap { set in
                    guard set.distance > 0, set.durationSeconds > 0 else { return nil }
                    let distance = unitSettings.distanceUnit.convert(fromMiles: set.distance)
                    return (Double(set.durationSeconds) / 60) / distance
                }
                return paces.min()
            }
            
        case .repsOnly:
            guard let maxReps = instance.sets.map(\.reps).max(), maxReps > 0 else { return nil }
            return Double(maxReps)
        }
    }
    
    private var bestValue: Double? {
        if loggingType == .distanceTime && selectedMetric == .secondary {
            return dataPoints.map(\.value).min() // lower pace = better
        }
        return dataPoints.map(\.value).max()
    }
    
    private var mostRecentValue: Double? {
        dataPoints.last?.value
    }
    
    private func formatValue(_ value: Double) -> String {
        if loggingType == .time || (loggingType == .timeWeight && selectedMetric == .primary) {
            let minutes = Int(value) / 60
            let seconds = Int(value) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        if loggingType == .distanceTime && selectedMetric == .secondary {
            let minutes = Int(value)
            let seconds = Int((value - Double(minutes)) * 60)
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "%.1f", value)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let muscleTargetsSummary {
                    Text(muscleTargetsSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                if dataPoints.isEmpty {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Log a few sessions with this exercise to see your progress over time.")
                    )
                    .padding(.top, 40)
                } else {
                    if availableMetrics.count > 1 {
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(availableMetrics, id: \.self) { metric in
                                Text(metric.label(for: loggingType)).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    
                    HStack(spacing: 20) {
                        if let bestValue {
                            StatBlock(label: "Best", value: formatValue(bestValue), unit: unitLabel)
                        }
                        if let mostRecentValue {
                            StatBlock(label: "Most Recent", value: formatValue(mostRecentValue), unit: unitLabel)
                        }
                    }
                    .padding(.horizontal)
                    
                    Chart(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(selectedMetric.label(for: loggingType), point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent)
                        
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(selectedMetric.label(for: loggingType), point.value)
                        )
                        .foregroundStyle(Theme.accent)
                    }
                    .frame(height: 220)
                    .padding(.horizontal)
                    .chartYAxisLabel(unitLabel)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Edit exercise")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ExerciseFormView(editing: exercise) { _ in }
        }
    }
}

private struct StatBlock: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value) \(unit)")
                .font(.title3.bold())
        }
    }
}
