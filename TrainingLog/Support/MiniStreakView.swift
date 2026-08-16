import SwiftUI
import SwiftData

struct MiniStreakView: View {
    @Query private var workoutDays: [WorkoutDay]
    
    private let calendar = Calendar.current
    
    private var activityMap: [Date: Int] {
        WorkoutCalculations.activityByDay(from: workoutDays)
    }
    
    private var last7Days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }
    
    private func weekdayLetter(for date: Date) -> String {
        let symbols = calendar.veryShortWeekdaySymbols
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        return symbols[weekdayIndex]
    }
    
    var body: some View {
        HStack {
            ForEach(last7Days, id: \.self) { day in
                VStack(spacing: 4) {
                    dot(for: day)
                    Text(weekdayLetter(for: day))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(calendar.isDateInToday(day) ? Theme.accent : .secondary)
                }
                if day != last7Days.last {
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func dot(for day: Date) -> some View {
        let intensity = activityMap[day] ?? 0
        let isToday = calendar.isDateInToday(day)
        
        Circle()
            .fill(intensity > 0 ? Theme.accent : Color(.systemGray))
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(isToday ? Theme.accent : .clear, lineWidth: 1.5)
                    .frame(width: 12, height: 12)
            )
    }
}
