//
//  MuscleTargetPickerView.swift
//  TrainingLog
//

import SwiftUI

/// A multi-select list of specific muscles, grouped by their broad
/// `MuscleGroup` for scanability — used for both the primary and
/// secondary muscle pickers in `ExerciseFormView`, distinguished by
/// `title` and by `excluding` (whichever muscles are already claimed by
/// the *other* picker, so the same muscle can't be both primary and
/// secondary at once).
struct MuscleTargetPickerView: View {
    let title: String
    var excluding: Set<MuscleTarget> = []
    @Binding var selection: Set<MuscleTarget>

    private var groupedTargets: [(group: MuscleGroup, targets: [MuscleTarget])] {
        let grouped = Dictionary(grouping: MuscleTarget.allCases) { $0.muscleGroup }
        return MuscleGroup.allCases.compactMap { group in
            guard let targets = grouped[group], !targets.isEmpty else { return nil }
            return (group, targets)
        }
    }

    var body: some View {
        List {
            ForEach(groupedTargets, id: \.group) { entry in
                let available = entry.targets.filter { !excluding.contains($0) }

                if !available.isEmpty {
                    Section(entry.group.rawValue) {
                        ForEach(available) { target in
                            Button {
                                toggle(target)
                            } label: {
                                HStack {
                                    Text(target.rawValue)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selection.contains(target) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ target: MuscleTarget) {
        if selection.contains(target) {
            selection.remove(target)
        } else {
            selection.insert(target)
        }
    }
}
