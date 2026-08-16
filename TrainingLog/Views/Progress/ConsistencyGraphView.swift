//
//  ConsistencyGraphView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct ConsistencyGraphView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    @Query private var workoutDays: [WorkoutDay]
    
    private let calendar = Calendar.current
    private let accentColor = Theme.accent
    
    private var activityMap: [Date: Int] {
        WorkoutCalculations.activityByDay(from: workoutDays)
    }
    
    private var weeks: [[Date]] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSaturday = 7 - weekday
        guard let gridEnd = calendar.date(byAdding: .day, value: daysUntilSaturday, to: today) else { return [] }
        guard let gridStart = calendar.date(byAdding: .day, value: -(52 * 7 - 1), to: gridEnd) else { return [] }
        
        var allDays: [Date] = []
        var current = gridStart
        while current <= gridEnd {
            allDays.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return stride(from: 0, to: allDays.count, by: 7).map {
            Array(allDays[$0..<min($0 + 7, allDays.count)])
        }
    }
    
    private var monthLabels: [Int: String] {
        var labels: [Int: String] = [:]
        var lastMonth: Int? = nil
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        for (index, week) in weeks.enumerated() {
            guard let firstDay = week.first else { continue }
            let month = calendar.component(.month, from: firstDay)
            
            if month != lastMonth {
                labels[index] = formatter.string(from: firstDay)
                lastMonth = month
            }
        }
        
        return labels
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 4) {
                                ForEach(weeks.indices, id: \.self) { weekIndex in
                                    Text(monthLabels[weekIndex] ?? "")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .fixedSize()
                                        .frame(width: 14, alignment: .leading)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 4) {
                                ForEach(weeks.indices, id: \.self) { weekIndex in
                                    VStack(spacing: 4) {
                                        ForEach(weeks[weekIndex], id: \.self) { date in
                                            DayDot(
                                                date: date,
                                                intensity: activityMap[date] ?? 0,
                                                isFuture: date > calendar.startOfDay(for: Date()),
                                                accentColor: accentColor
                                            )
                                        }
                                    }
                                    .id(weekIndex)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .frame(minWidth: geometry.size.width, alignment: .trailing)
                    }
                    .onAppear {
                        scrollToMostRecentWeek(proxy: proxy)
                    }
                }
            }
            .frame(height: 7 * 17 + 16)
            
            HStack(spacing: 6) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5) { level in
                    Circle()
                        .fill(colorForLevel(level, accentColor: accentColor))
                        .frame(width: 9, height: 9)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func scrollToMostRecentWeek(proxy: ScrollViewProxy) {
        guard let lastIndex = weeks.indices.last else { return }
        proxy.scrollTo(lastIndex, anchor: .trailing)
    }
}

private struct DayDot: View {
    let date: Date
    let intensity: Int
    let isFuture: Bool
    let accentColor: Color
    
    private var level: Int {
        switch intensity {
        case 0: return 0
        case 1...5: return 1
        case 6...12: return 2
        case 13...20: return 3
        default: return 4
        }
    }
    
    var body: some View {
        Circle()
            .fill(isFuture ? Color.clear : colorForLevel(level, accentColor: accentColor))
            .frame(width: 14, height: 14)
    }
}

private func colorForLevel(_ level: Int, accentColor: Color) -> Color {
    switch level {
    case 0: return Color(.systemGray5)
    case 1: return accentColor.opacity(0.25)
    case 2: return accentColor.opacity(0.45)
    case 3: return accentColor.opacity(0.7)
    default: return accentColor
    }
}
