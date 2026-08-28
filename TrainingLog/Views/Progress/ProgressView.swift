//
//  ExerciseListProgressView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct ProgressView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query private var allWorkoutExercises: [WorkoutExercise]

    @State private var searchText = ""
    @State private var sortOption: SortOption = .muscleGroup

    /// How many days since an exercise was last logged before it's
    /// surfaced in "Needs Attention."
    private static let staleThresholdDays = 14

    private enum SortOption: String, CaseIterable, Identifiable {
        case muscleGroup = "Muscle Group"
        case recentlyTrained = "Recently Trained"
        case mostTrained = "Most Trained"
        case alphabetical = "A–Z"

        var id: String { rawValue }
    }

    private enum Trend {
        case up, down, flat
    }

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var groupedExercises: [MuscleGroup: [Exercise]] {
        Dictionary(grouping: filteredExercises, by: { $0.muscleGroup })
    }

    /// Every logged instance of every exercise, grouped by which exercise
    /// it belongs to — the source for last-trained dates and trends
    /// without re-filtering `allWorkoutExercises` per row.
    private var historyByExercise: [PersistentIdentifier: [WorkoutExercise]] {
        Dictionary(grouping: allWorkoutExercises) { $0.exercise.persistentModelID }
    }

    private var flatSortedExercises: [Exercise] {
        switch sortOption {
        case .muscleGroup, .alphabetical:
            return filteredExercises
        case .recentlyTrained:
            return filteredExercises.sorted {
                (lastTrainedDate(for: $0) ?? .distantPast) > (lastTrainedDate(for: $1) ?? .distantPast)
            }
        case .mostTrained:
            return filteredExercises.sorted {
                (historyByExercise[$0.persistentModelID]?.count ?? 0)
                    > (historyByExercise[$1.persistentModelID]?.count ?? 0)
            }
        }
    }

    /// Exercises with history that's gone stale — sorted most-overdue
    /// first. Only meaningful outside of search, same as the dashboard
    /// cards above the list.
    private var staleExercises: [Exercise] {
        guard let threshold = Calendar.current.date(
            byAdding: .day,
            value: -Self.staleThresholdDays,
            to: Date()
        ) else { return [] }

        return exercises
            .filter { exercise in
                guard let last = lastTrainedDate(for: exercise) else { return false }
                return last < threshold
            }
            .sorted {
                (lastTrainedDate(for: $0) ?? .distantPast) < (lastTrainedDate(for: $1) ?? .distantPast)
            }
    }

    private func lastTrainedDate(for exercise: Exercise) -> Date? {
        historyByExercise[exercise.persistentModelID]?.map(\.loggedAt).max()
    }

    private func daysAgo(_ date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
    }

    /// Whether the exercise's primary metric improved, held, or dropped
    /// between its two most recent logged instances. Every primary
    /// metric (weight, reps, hold duration, distance) is "higher is
    /// better," so a single up/down reading works for every logging
    /// type without special-casing.
    private func trend(for exercise: Exercise) -> Trend? {
        guard let history = historyByExercise[exercise.persistentModelID] else { return nil }

        // Compared within a single variation — "how is what I'm currently
        // doing going" — rather than across all of them. An incline
        // session following a heavier flat one isn't a decline, and
        // reading it as one would put a down arrow on the row every time
        // the user switched variation.
        let sorted = history.sorted { $0.loggedAt < $1.loggedAt }
        guard let latest = sorted.last else { return nil }
        let currentVariant = latest.variant?.persistentModelID

        let values = sorted
            .filter { $0.variant?.persistentModelID == currentVariant }
            .compactMap { WorkoutCalculations.primaryMetricValue(for: $0) }

        guard values.count >= 2 else { return nil }
        let last = values[values.count - 1]
        let previous = values[values.count - 2]

        if last > previous { return .up }
        if last < previous { return .down }
        return .flat
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section {
                        ProgressOverviewView()
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        PersonalRecordsView()
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        ConsistencyGraphView()
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                    }

                    needsAttentionSection
                }

                if filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if sortOption == .muscleGroup {
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        if let groupExercises = groupedExercises[group], !groupExercises.isEmpty {
                            Section {
                                ForEach(groupExercises) { exercise in
                                    exerciseRow(exercise)
                                }
                            } header: {
                                Text(group.rawValue)
                            }
                        }
                    }
                } else {
                    Section {
                        ForEach(flatSortedExercises) { exercise in
                            exerciseRow(exercise)
                        }
                    } header: {
                        Text("Exercises")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Progress")
            .scrollContentBackground(.hidden)
            .background(SpinningGradientBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Sort exercises")
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
        }
    }

    // MARK: - Needs Attention

    @ViewBuilder
    private var needsAttentionSection: some View {
        let stale = Array(staleExercises.prefix(5))

        if !stale.isEmpty {
            Section {
                ForEach(stale) { exercise in
                    NavigationLink {
                        ExerciseProgressView(exercise: exercise)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(exercise.name)

                                if let last = lastTrainedDate(for: exercise) {
                                    Text("Last trained \(daysAgo(last)) days ago")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Needs Attention")
            }
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        NavigationLink {
            ExerciseProgressView(exercise: exercise)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: exercise.muscleGroup.icon)
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 22)

                Text(exercise.name)

                trendIcon(for: exercise)

                if exercise.isCustom {
                    Spacer()
                    Text("Custom")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func trendIcon(for exercise: Exercise) -> some View {
        switch trend(for: exercise) {
        case .up:
            Image(systemName: "arrow.up.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
        case .down:
            Image(systemName: "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
        case .flat, .none:
            EmptyView()
        }
    }
}
