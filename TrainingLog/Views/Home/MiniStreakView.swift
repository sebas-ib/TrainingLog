//
//  MiniStreakView.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/15/26.
//
import SwiftUI
import SwiftData

struct MiniStreakView: View {
    @Query private var workoutDays: [WorkoutDay]
    @Binding var selectedDate: Date

    @Namespace private var selectionNamespace

    private let calendar = Calendar.current
    private let visibleDaysCount = 7

    @State private var windowStart: Date

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate

        let calendar = Calendar.current
        let normalizedSelected = calendar.startOfDay(for: selectedDate.wrappedValue)
        let today = calendar.startOfDay(for: Date())

        // Default to the trailing 7 days ending today, unless the selected
        // date is already outside that range.
        let defaultStart = calendar.date(byAdding: .day, value: -(visibleDaysCount - 1), to: today) ?? today
        let defaultEnd = today

        if normalizedSelected >= defaultStart && normalizedSelected <= defaultEnd {
            _windowStart = State(initialValue: defaultStart)
        } else {
            _windowStart = State(initialValue: normalizedSelected)
        }
    }

    // MARK: - Activity

    private var activityMap: [Date: Int] {
        var normalizedMap: [Date: Int] = [:]
        for (date, count) in WorkoutCalculations.activityByDay(from: workoutDays) {
            normalizedMap[calendar.startOfDay(for: date)] = count
        }
        return normalizedMap
    }

    // MARK: - Visible Days

    private var visibleDays: [Date] {
        (0..<visibleDaysCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: windowStart)
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(visibleDays, id: \.self) { day in
                dayColumn(for: day)
                    .frame(maxWidth: .infinity)
            }
        }
        .id(windowStart)
        .transition(.opacity)
        .frame(height: 40)
        .onChange(of: selectedDate) { _, newDate in
            syncWindow(to: newDate)
        }
    }

    // MARK: - Day Column

    @ViewBuilder
    private func dayColumn(for day: Date) -> some View {
        VStack(spacing: 4) {
            dot(for: day)
            Text(weekdayLetter(for: day))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isSelected(day) ? Theme.accent : .secondary)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Weekday

    private func weekdayLetter(for date: Date) -> String {
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        return calendar.veryShortWeekdaySymbols[weekdayIndex]
    }

    // MARK: - Selection

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    // MARK: - Dot

    @ViewBuilder
    private func dot(for day: Date) -> some View {
        let normalizedDay = calendar.startOfDay(for: day)
        let intensity = activityMap[normalizedDay] ?? 0
        let selected = isSelected(normalizedDay)

        ZStack {
            Circle()
                .fill(intensity > 0 ? Theme.accent : Color(.systemGray))
                .frame(width: 8, height: 8)

            if selected {
                Circle()
                    .stroke(Theme.accent, lineWidth: 1.5)
                    .frame(width: 12, height: 12)
                    .matchedGeometryEffect(id: "selection", in: selectionNamespace)
            }
        }
        .frame(width: 16, height: 16)
    }

    // MARK: - Window Synchronization

    private func syncWindow(to date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)
        let windowEnd = calendar.date(byAdding: .day, value: visibleDaysCount - 1, to: windowStart) ?? windowStart

        // Already visible — no need to move the window, just let the
        // selection ring/text color update (which isn't animated by
        // the fade transition since windowStart doesn't change).
        guard normalizedDate < windowStart || normalizedDate > windowEnd else { return }

        let newStart: Date
        if normalizedDate < windowStart {
            newStart = normalizedDate
        } else {
            newStart = calendar.date(byAdding: .day, value: -(visibleDaysCount - 1), to: normalizedDate) ?? normalizedDate
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            windowStart = newStart
        }
    }
}
