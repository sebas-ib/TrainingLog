//
//  GoalProgressBar.swift
//  TrainingLog
//

import SwiftUI

/// A slim horizontal "loading bar" showing sets completed against a
/// weekly target — accent-colored while still short of goal, green once
/// it's met or exceeded (values past the goal just show a full bar,
/// never an overflowing one).
struct GoalProgressBar: View {
    let current: Int
    let goal: Int

    private var fraction: Double {
        guard goal > 0 else { return current > 0 ? 1 : 0 }
        return min(Double(current) / Double(goal), 1)
    }

    private var isComplete: Bool {
        goal > 0 && current >= goal
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))

                Capsule()
                    .fill(isComplete ? Color.green : Theme.accent)
                    .frame(width: geometry.size.width * fraction)
            }
        }
    }
}
