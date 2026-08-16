import SwiftUI

struct WorkoutSummaryView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    let session: WorkoutSession
    
    private var muscleGroupVolumes: [(group: MuscleGroup, volume: Double)] {
        WorkoutCalculations.volumeByMuscleGroup(for: session)
            .map { (group: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                SummaryStat(
                    label: "Sets",
                    value: "\(WorkoutCalculations.totalSets(for: session))"
                )
                SummaryStat(
                    label: "Reps",
                    value: "\(WorkoutCalculations.totalReps(for: session))"
                )
                SummaryStat(
                    label: "Exercises",
                    value: "\(session.exercises.count)"
                )
            }
            
            if !muscleGroupVolumes.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Volume by Muscle Group")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(muscleGroupVolumes, id: \.group) { entry in
                        HStack {
                            Image(systemName: entry.group.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            Text(entry.group.rawValue)
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(unitSettings.unit.convert(fromLbs: entry.volume))) \(unitSettings.unit.rawValue)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor.secondarySystemBackground
                    : UIColor.tertiarySystemBackground
            })
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SummaryStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
