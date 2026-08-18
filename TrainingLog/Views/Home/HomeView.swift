//
//  HomeView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutDay.date, order: .reverse)
    private var workoutDays: [WorkoutDay]

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var saveError: Error?
    @State private var showingNewWorkoutSheet = false
    @State private var activeWorkoutSession: WorkoutSession?
    @State private var datePickerExpanded = false
    @State private var gradientRotation: Double = 0
    
    private let calendar = Calendar.current

    private var selectedDay: WorkoutDay? {
        workoutDays.first {
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    private var relativeDateLabel: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
    
    private var isFutureBlocked: Bool {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return true }
        return nextDay > calendar.startOfDay(for: Date())
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button {
                                stepDate(by: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderless)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    datePickerExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(relativeDateLabel)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(Theme.accent)
                                        .rotationEffect(.degrees(datePickerExpanded ? 180 : 0))
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Button {
                                stepDate(by: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderless)
                            .disabled(isFutureBlocked)
                            .opacity(isFutureBlocked ? 0.3 : 1)
                        }
                        
                        DaySummaryView(
                            day: selectedDay,
                            isExpanded: datePickerExpanded,
                            selectedDate: $selectedDate
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                datePickerExpanded.toggle()
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.cardBackground)
                    .padding()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                let horizontal = value.translation.width
                                let vertical = value.translation.height
                                
                                guard abs(horizontal) > abs(vertical) else { return }
                                
                                if horizontal < 0 {
                                    stepDate(by: 1)
                                } else {
                                    stepDate(by: -1)
                                }
                            }
                    )
                    
                    if datePickerExpanded {
                        DatePicker(
                            "Select Day",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(Theme.accent)
                        .onChange(of: selectedDate) { _, newValue in
                            selectedDate = calendar.startOfDay(for: newValue)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                
                if let day = selectedDay, !day.sessions.isEmpty {
                    WorkoutListView(
                        workoutDay: day,
                        onWorkoutSessionCreated: { newWorkout in
                            scheduleNavigation(to: newWorkout)
                        },
                        onWorkoutSessionSelected: { existingWorkout in
                            activeWorkoutSession = existingWorkout
                        }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                } else {
                    emptyWorkoutSection
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            )
                        )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(SpinningGradientBackground())
            .tint(Theme.accent)
            .navigationTitle("Workout Tracker")
            .toolbar {
                if !isToday {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Today") {
                            withAnimation {
                                selectedDate = calendar.startOfDay(for: Date())
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingNewWorkoutSheet) {
                NewWorkoutSessionView(targetDate: selectedDate) { newWorkout in
                    attachNewWorkout(newWorkout)
                    scheduleNavigation(to: newWorkout)
                }
                .tint(Theme.accent)
            }
            .navigationDestination(item: $activeWorkoutSession) { workout in
                WorkoutDetailView(session: workout)
            }
            .alert(
                "Couldn't Save Workout",
                isPresented: saveErrorBinding
            ) {
                Button("OK", role: .cancel) {
                    saveError = nil
                }
            } message: {
                Text(
                    saveError?.localizedDescription
                    ?? "An unknown error occurred while saving your workout."
                )
            }
        }
    }

    private var emptyWorkoutSection: some View {
        Section {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.top, 4)

                VStack(spacing: 4) {
                    Text(isToday ? "No Workout Today" : "No Workout Logged")
                        .font(.title3.bold())
                    Text("Tap below to start tracking your workout.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    showingNewWorkoutSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Start Workout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.large)
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 220)
            .padding(.vertical, 20)
        }
        .transition(
            .asymmetric(
                insertion: .opacity,
                removal: .scale(scale: 0.95).combined(with: .opacity)
            )
        )
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { isPresented in
                if !isPresented { saveError = nil }
            }
        )
    }
    
    private func stepDate(by days: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else { return }
        let today = calendar.startOfDay(for: Date())
        guard newDate <= today else { return }
        withAnimation {
            selectedDate = newDate
        }
    }
    
    private func attachNewWorkout(_ workout: WorkoutSession) {
        let day: WorkoutDay
        if let existing = selectedDay {
            day = existing
        } else {
            day = WorkoutDay(date: selectedDate)
            modelContext.insert(day)
        }
        day.sessions.append(workout)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            saveError = error
        }
    }
    
    private func scheduleNavigation(to workout: WorkoutSession) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            activeWorkoutSession = workout
        }
    }
}
