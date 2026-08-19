//
//  PersonalRecordsView.swift
//  TrainingLog
//

import SwiftUI
import SwiftData

/// The most recent personal records across every exercise — nothing in
/// the app surfaced a PR moment at all before this, even though every
/// set logged already carries the data to detect one.
struct PersonalRecordsView: View {
    @Query(sort: \WorkoutExercise.loggedAt, order: .forward) private var allWorkoutExercises: [WorkoutExercise]

    private var records: [PersonalRecord] {
        Array(WorkoutCalculations.recentPersonalRecords(from: allWorkoutExercises).prefix(6))
    }

    var body: some View {
        if !records.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.yellow)

                    Text("Recent Personal Records")
                        .font(Theme.sectionHeader())
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ForEach(records) { record in
                        PersonalRecordRow(record: record)

                        if record.id != records.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding()
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct PersonalRecordRow: View {
    let record: PersonalRecord
    @EnvironmentObject private var unitSettings: UnitSettings

    private var formattedValue: String {
        switch record.exercise.loggingType {
        case .weightReps:
            let converted = unitSettings.unit.convert(fromLbs: record.value)
            return "\(String(format: "%.0f", converted)) \(unitSettings.unit.rawValue)"

        case .bodyweightReps, .repsOnly:
            return "\(Int(record.value)) reps"

        case .time, .timeWeight:
            return DurationFormatting.minutesSeconds(Int(record.value))

        case .distanceTime:
            let converted = unitSettings.distanceUnit.convert(fromMiles: record.value)
            return "\(String(format: "%.2f", converted)) \(unitSettings.distanceUnit.rawValue)"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.exercise.muscleGroup.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.accent.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(record.exercise.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Text(record.date, style: .date)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(formattedValue)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
        }
    }
}
