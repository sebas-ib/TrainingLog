//
//  DaySummaryView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI

struct DaySummaryView: View {
    let date: Date
    let day: WorkoutDay?
    let isExpanded: Bool
    let onTap: () -> Void
    
    private var workoutCount: Int {
        day?.sessions.count ?? 0
    }
    
    private var totalSets: Int {
        guard let day else { return 0 }
        return WorkoutCalculations.totalSets(for: day)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                Label("\(workoutCount) session\(workoutCount == 1 ? "" : "s")", systemImage: "figure.strengthtraining.traditional")
                    .contentTransition(.numericText())
                Label("\(totalSets) sets", systemImage: "list.number")
                    .contentTransition(.numericText())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            
            MiniStreakView()
        }
        .frame(maxWidth: .infinity)
    }
}
