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
    @State private var selectedMetric: Metric = .primary

    /// nil means "All variations" — only offered when they're actually
    /// comparable (see `canCompareAll`).
    @State private var selectedSeriesID: String?
    @State private var hasChosenSeries = false

    // MARK: - Series

    private var series: [WorkoutCalculations.VariationSeries] {
        WorkoutCalculations.variationSeries(for: exercise, in: allWorkoutExercises)
    }

    /// Overlaying variations on one chart only makes sense when they're
    /// measured the same way. A weighted plank (seconds *and* load)
    /// against a plain one (seconds) would put two different units on a
    /// single Y axis, so in that case the chart shows one at a time.
    private var canCompareAll: Bool {
        series.count > 1 && WorkoutCalculations.sharesLoggingType(series)
    }

    /// Defaults to comparing everything when that's meaningful, and
    /// otherwise to whichever variation was logged most recently — the
    /// one the user is presumably here to look at.
    private var effectiveSeriesID: String? {
        if hasChosenSeries { return selectedSeriesID }
        if canCompareAll { return nil }
        return mostRecentSeries?.id ?? series.first?.id
    }

    private var mostRecentSeries: WorkoutCalculations.VariationSeries? {
        series.max {
            ($0.instances.last?.loggedAt ?? .distantPast)
                < ($1.instances.last?.loggedAt ?? .distantPast)
        }
    }

    private var displayedSeries: [WorkoutCalculations.VariationSeries] {
        guard let id = effectiveSeriesID else { return series }
        return series.filter { $0.id == id }
    }

    /// The variation being looked at, when it's exactly one — drives the
    /// muscle summary, which would otherwise claim the parent's muscles
    /// while showing a variation that retargets them.
    private var focusedVariant: ExerciseVariant? {
        displayedSeries.count == 1 ? displayedSeries.first?.variant : nil
    }

    private var loggingType: ExerciseLoggingType {
        displayedSeries.first?.loggingType ?? exercise.loggingType
    }

    // MARK: - Muscles

    private var muscleTargetsSummary: String? {
        let primary = exercise.primaryTargets(for: focusedVariant)
        guard !primary.isEmpty else { return nil }

        var text = primary.map(\.displayName).joined(separator: ", ")
        let secondary = exercise.secondaryTargets(for: focusedVariant)
        if !secondary.isEmpty {
            text += " · also " + secondary.map(\.displayName).joined(separator: ", ")
        }
        return text
    }

    // MARK: - Metrics

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

    private func points(for series: WorkoutCalculations.VariationSeries) -> [DataPoint] {
        series.instances.compactMap { instance in
            guard let value = metricValue(for: instance) else { return nil }
            return DataPoint(date: instance.loggedAt, value: value)
        }
    }

    private var allDisplayedPoints: [DataPoint] {
        displayedSeries.flatMap { points(for: $0) }.sorted { $0.date < $1.date }
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
            return allDisplayedPoints.map(\.value).min() // lower pace = better
        }
        return allDisplayedPoints.map(\.value).max()
    }

    private var mostRecentValue: Double? {
        allDisplayedPoints.last?.value
    }

    private func formatValue(_ value: Double) -> String {
        if loggingType == .time || (loggingType == .timeWeight && selectedMetric == .primary) {
            return DurationFormatting.minutesSeconds(Int(value))
        }
        if loggingType == .distanceTime && selectedMetric == .secondary {
            let minutes = Int(value)
            let seconds = Int((value - Double(minutes)) * 60)
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "%.1f", value)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if series.count > 1 {
                    variationPicker
                }

                if let muscleTargetsSummary {
                    Text(muscleTargetsSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                if allDisplayedPoints.isEmpty {
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

                    chart
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
        .onChange(of: loggingType) {
            // Switching to a variation that's measured differently can
            // leave a metric selected that no longer exists for it —
            // "Volume" has no meaning once the chart is showing seconds.
            if selectedMetric == .secondary, availableMetrics.count == 1 {
                selectedMetric = .primary
            }
        }
    }

    // MARK: - Variation Picker

    @ViewBuilder
    private var variationPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker(
                "Variation",
                selection: Binding(
                    get: { effectiveSeriesID },
                    set: {
                        selectedSeriesID = $0
                        hasChosenSeries = true
                    }
                )
            ) {
                if canCompareAll {
                    Text("All Variations").tag(String?.none)
                }
                ForEach(series) { entry in
                    Text(entry.label).tag(String?.some(entry.id))
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)

            if !canCompareAll {
                Text("These variations are tracked differently, so they're shown one at a time.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            if displayedSeries.count > 1 {
                ForEach(displayedSeries) { entry in
                    ForEach(points(for: entry)) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(selectedMetric.label(for: loggingType), point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Variation", entry.label))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(selectedMetric.label(for: loggingType), point.value)
                        )
                        .foregroundStyle(by: .value("Variation", entry.label))
                    }
                }
            } else {
                ForEach(allDisplayedPoints) { point in
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
            }
        }
        .chartLegend(displayedSeries.count > 1 ? .visible : .hidden)
        .frame(height: 220)
        .padding(.horizontal)
        .chartYAxisLabel(unitLabel)
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
