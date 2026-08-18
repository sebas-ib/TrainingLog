//
//  NewWorkoutSessionView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct NewWorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var allSessions: [WorkoutSession]

    let targetDate: Date
    let onCreate: (WorkoutSession) -> Void

    @State private var sessionName: String = ""
    @State private var sessionStartTime: Date

    init(targetDate: Date, onCreate: @escaping (WorkoutSession) -> Void) {
        self.targetDate = targetDate
        self.onCreate = onCreate
        _sessionStartTime = State(initialValue: Self.defaultStartTime(for: targetDate))
        
        let dateString = targetDate.formatted( .dateTime .month(.abbreviated) .day() )
        _sessionName = State( initialValue: "\(dateString) Workout" )
    }

    private var pastSessions: [WorkoutSession] {
        allSessions.filter { !$0.exercises.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workout Session Name (Optional)", text: $sessionName)
                        .font(.system(.body, design: .rounded))
                } header: {
                    Text("Name")
                }

                Section {
                    DatePicker(
                        "Time",
                        selection: $sessionStartTime,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("When")
                } footer: {
                    Text("Workout will be logged for \(targetDate.formatted(.dateTime.month(.abbreviated).day().year()))")
                }

                Section {
                    Button {
                        createBlankSession()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Start Blank Workout Session")
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                Text("Build it as you go")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundStyle(Theme.accent)
                }

                if !pastSessions.isEmpty {
                    Section {
                        ForEach(pastSessions.prefix(20)) { session in
                            Button {
                                createSessionFromTemplate(session)
                            } label: {
                                TemplateRow(session: session)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Or Use a Previous Workout Session")
                    } footer: {
                        Text("Exercises and set counts will be copied over. Reps and weights start fresh, with your last numbers shown as a reference.")
                    }
                }
            }
            .tint(Theme.accent)
            .navigationTitle("New Workout Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private static func defaultStartTime(for targetDate: Date) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0,
            of: targetDate
        ) ?? targetDate
    }

    private func createBlankSession() {
        let session = WorkoutSession(
            startTime: sessionStartTime,
            name: sessionName.isEmpty ? nil : sessionName
        )
        onCreate(session)
        dismiss()
    }

    private func createSessionFromTemplate(_ template: WorkoutSession) {
        let session = WorkoutSession(
            startTime: sessionStartTime,
            name: sessionName.isEmpty ? template.name : sessionName
        )

        let sortedTemplateExercises = template.exercises.sorted { $0.order < $1.order }

        for (index, templateExercise) in sortedTemplateExercises.enumerated() {
            let newWorkoutExercise = WorkoutExercise(
                exercise: templateExercise.exercise,
                loggedAt: sessionStartTime,
                order: index + 1
            )
            let sortedTemplateSets = templateExercise.sets.sorted(by: { $0.order < $1.order })

            for templateSet in sortedTemplateSets {
                newWorkoutExercise.sets.append(ExerciseSet(reps: 0, weight: 0, order: templateSet.order))
            }

            session.exercises.append(newWorkoutExercise)
        }

        onCreate(session)
        dismiss()
    }
}

private struct TemplateRow: View {
    let session: WorkoutSession

    private var exerciseNames: String {
        session.exercises.map { $0.exercise.name }.joined(separator: ", ")
    }

    private var setCount: Int {
        session.exercises.reduce(0) { $0 + $1.sets.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.name ?? "Workout Session")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(exerciseNames)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.caption2)
                Text("\(session.exercises.count) exercise\(session.exercises.count == 1 ? "" : "s") · \(setCount) sets")
                    .font(.caption2)
            }
            .foregroundStyle(Theme.accent)
        }
        .padding(.vertical, 4)
    }
}
