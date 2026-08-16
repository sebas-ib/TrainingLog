//
//  SetRowView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//

import SwiftUI
import SwiftData

enum SetField: Hashable {
    case reps(PersistentIdentifier)
    case weight(PersistentIdentifier)
    case bodyWeightModifier(PersistentIdentifier)
    case durationMinutes(PersistentIdentifier)
    case durationSeconds(PersistentIdentifier)
    case distance(PersistentIdentifier)
}

struct SetRowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings

    @Bindable var set: ExerciseSet

    let loggingType: ExerciseLoggingType
    var focusedField: FocusState<SetField?>.Binding
    var previousSet: ExerciseSet?

    @State private var pendingSave: DispatchWorkItem?
    @State private var hasAppeared = false

    // MARK: - Saving

    private func scheduleSave() {
        pendingSave?.cancel()

        let work = DispatchWorkItem {
            try? modelContext.save()
        }

        pendingSave = work

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.4,
            execute: work
        )
    }

    private func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        try? modelContext.save()
    }

    // MARK: - Unit Conversion

    private var displayWeight: Binding<Double> {
        Binding(
            get: {
                unitSettings.unit.convert(fromLbs: set.weight)
            },
            set: { newValue in
                set.weight = max(
                    0,
                    unitSettings.unit.convertToLbs(newValue)
                )
                scheduleSave()
            }
        )
    }

    private var displayBodyWeightModifier: Binding<Double> {
        Binding(
            get: {
                unitSettings.unit.convert(
                    fromLbs: set.bodyWeightModifier
                )
            },
            set: { newValue in
                // Body weight modifier can legitimately be negative
                // (assisted exercises), so no clamping here.
                set.bodyWeightModifier =
                    unitSettings.unit.convertToLbs(newValue)

                scheduleSave()
            }
        )
    }

    private var repsBinding: Binding<Int> {
        Binding(
            get: { set.reps },
            set: { newValue in
                set.reps = max(0, newValue)
                scheduleSave()
            }
        )
    }

    private var distanceBinding: Binding<Double> {
        Binding(
            get: { set.distance },
            set: { newValue in
                set.distance = max(0, newValue)
                scheduleSave()
            }
        )
    }

    // MARK: - Duration

    private var durationMinutes: Binding<Int> {
        Binding(
            get: {
                set.durationSeconds / 60
            },
            set: { newValue in
                let seconds = set.durationSeconds % 60
                set.durationSeconds = max(0, newValue) * 60 + seconds
                scheduleSave()
            }
        )
    }

    private var durationSecondsOnly: Binding<Int> {
        Binding(
            get: {
                set.durationSeconds % 60
            },
            set: { newValue in
                let minutes = set.durationSeconds / 60
                set.durationSeconds = minutes * 60 + max(0, newValue)
                scheduleSave()
            }
        )
    }

    // MARK: - Previous Set

    private var previousHint: String? {
        guard let previousSet else {
            return nil
        }

        var parts: [String] = []

        switch loggingType {
        case .weightReps:
            let weight = unitSettings.unit.convert(
                fromLbs: previousSet.weight
            )

            parts.append(
                "\(previousSet.reps) × \(String(format: "%.0f", weight)) \(unitSettings.unit.rawValue)"
            )

        case .bodyweightReps:
            parts.append("\(previousSet.reps) reps")

            if previousSet.bodyWeightModifier != 0 {
                let modifier = unitSettings.unit.convert(
                    fromLbs: previousSet.bodyWeightModifier
                )

                let formattedModifier =
                    String(format: "%.0f", modifier)

                if modifier > 0 {
                    parts.append(
                        "+\(formattedModifier) \(unitSettings.unit.rawValue)"
                    )
                } else {
                    parts.append(
                        "\(formattedModifier) \(unitSettings.unit.rawValue)"
                    )
                }
            }

        case .time:
            parts.append(
                formattedDuration(previousSet.durationSeconds)
            )

        case .timeWeight:
            let weight = unitSettings.unit.convert(
                fromLbs: previousSet.weight
            )

            parts.append(
                "\(formattedDuration(previousSet.durationSeconds)) @ \(String(format: "%.0f", weight)) \(unitSettings.unit.rawValue)"
            )

        case .distanceTime:
            parts.append(
                "\(String(format: "%.2f", previousSet.distance)) mi in \(formattedDuration(previousSet.durationSeconds))"
            )

        case .repsOnly:
            parts.append("\(previousSet.reps) reps")
        }

        if previousSet.takenToFailure {
            parts.append("Failure")
        }

        return parts.joined(separator: " · ")
    }

    private func formattedDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        return String(
            format: "%d:%02d",
            minutes,
            seconds
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                setNumber
                fieldsForType
                Spacer(minLength: 4)
                failureButton
            }

            if let previousHint {
                previousSetButton(hint: previousHint)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(
            hasAppeared ? 1 : 0.96,
            anchor: .leading
        )
        .offset(
            y: hasAppeared ? 0 : 6
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                focusedField.wrappedValue = nil
            }
        )
        .onDisappear {
            saveNow()
        }
        .onAppear {
            let delay =
                min(Double(max(set.order - 1, 0)), 4) * 0.04

            withAnimation(
                .spring(
                    response: 0.38,
                    dampingFraction: 0.78
                )
                .delay(delay)
            ) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Set Number

    private var setNumber: some View {
        Text("\(set.order)")
            .font(
                .system(
                    size: 13,
                    weight: .semibold
                )
            )
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .frame(
                width: 28,
                alignment: .leading
            )
    }

    // MARK: - Failure Button

    private var failureButton: some View {
        Button {
            let generator =
                UIImpactFeedbackGenerator(style: .light)

            generator.impactOccurred()

            withAnimation(
                .spring(
                    response: 0.3,
                    dampingFraction: 0.6
                )
            ) {
                set.takenToFailure.toggle()
            }

            saveNow()
        } label: {
            Image(
                systemName:
                    set.takenToFailure
                    ? "flame.fill"
                    : "flame"
            )
            .font(
                .system(
                    size: 14,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                set.takenToFailure
                ? .orange
                : .secondary
            )
            .frame(
                width: 34,
                height: 34
            )
            .background(
                Circle()
                    .fill(
                        set.takenToFailure
                        ? Color.orange.opacity(0.15)
                        : Color(.secondarySystemBackground)
                    )
            )
            .scaleEffect(
                set.takenToFailure ? 1.05 : 1
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            set.takenToFailure
            ? "Taken to failure"
            : "Not taken to failure"
        )
    }

    // MARK: - Previous Set

    @ViewBuilder
    private func previousSetButton(
        hint: String
    ) -> some View {
        Button {
            copyFromPrevious()
        } label: {
            HStack(spacing: 5) {
                Image(
                    systemName: "arrow.uturn.backward"
                )
                .font(.system(size: 10, weight: .semibold))

                Text(hint)
                    .font(
                        .system(
                            size: 11,
                            weight: .medium
                        )
                    )
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        Color(Theme.accent )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.leading, 36)
        .accessibilityLabel(
            "Copy last set: \(hint)"
        )
        .accessibilityHint(
            "Fills this set with the previous set's values"
        )
    }

    // MARK: - Copy Previous

    private func copyFromPrevious() {
        guard let previousSet else {
            return
        }

        let generator =
            UIImpactFeedbackGenerator(style: .light)

        generator.impactOccurred()

        withAnimation(
            .spring(
                response: 0.3,
                dampingFraction: 0.7
            )
        ) {
            switch loggingType {
            case .weightReps:
                set.reps = previousSet.reps
                set.weight = previousSet.weight

            case .bodyweightReps:
                set.reps = previousSet.reps
                set.bodyWeightModifier =
                    previousSet.bodyWeightModifier

            case .time:
                set.durationSeconds =
                    previousSet.durationSeconds

            case .timeWeight:
                set.durationSeconds =
                    previousSet.durationSeconds

                set.weight =
                    previousSet.weight

            case .distanceTime:
                set.distance =
                    previousSet.distance

                set.durationSeconds =
                    previousSet.durationSeconds

            case .repsOnly:
                set.reps =
                    previousSet.reps
            }
        }

        saveNow()
    }

    // MARK: - Reusable Fields

    private func intField(
        _ placeholder: String,
        value: Binding<Int>,
        width: CGFloat,
        focus: SetField
    ) -> some View {
        TextField(
            placeholder,
            value: value,
            format: .number
        )
        .keyboardType(.numberPad)
        .textFieldStyle(.plain)
        .font(
            .system(
                size: 16,
                weight: .semibold
            )
        )
        .monospacedDigit()
        .multilineTextAlignment(.center)
        .frame(width: width, height: 34)
        .focused(
            focusedField,
            equals: focus
        )
        .accessibilityLabel(placeholder)
    }

    private func doubleField(
        _ placeholder: String,
        value: Binding<Double>,
        width: CGFloat,
        keyboard: UIKeyboardType,
        focus: SetField
    ) -> some View {
        TextField(
            placeholder,
            value: value,
            format: .number
        )
        .keyboardType(keyboard)
        .textFieldStyle(.plain)
        .font(
            .system(
                size: 16,
                weight: .semibold
            )
        )
        .monospacedDigit()
        .multilineTextAlignment(.center)
        .frame(width: width, height: 34)
        .focused(
            focusedField,
            equals: focus
        )
        .accessibilityLabel(placeholder)
    }

    // MARK: - Duration Fields

    private func durationFields(
        width: CGFloat = 40
    ) -> some View {
        HStack(spacing: 3) {
            intField(
                "Min",
                value: durationMinutes,
                width: width,
                focus: .durationMinutes(
                    set.persistentModelID
                )
            )

            Text(":")
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)

            intField(
                "Sec",
                value: durationSecondsOnly,
                width: width,
                focus: .durationSeconds(
                    set.persistentModelID
                )
            )
        }
    }

    // MARK: - Fields By Type

    @ViewBuilder
    private var fieldsForType: some View {
        switch loggingType {

        case .weightReps:
            HStack(spacing: 5) {
                intField(
                    "Reps",
                    value: repsBinding,
                    width: 52,
                    focus: .reps(
                        set.persistentModelID
                    )
                )

                Text("×")
                    .foregroundStyle(.secondary)

                doubleField(
                    "Weight",
                    value: displayWeight,
                    width: 64,
                    keyboard: .decimalPad,
                    focus: .weight(
                        set.persistentModelID
                    )
                )

                unitLabel
            }

        case .bodyweightReps:
            HStack(spacing: 5) {
                intField(
                    "Reps",
                    value: repsBinding,
                    width: 52,
                    focus: .reps(
                        set.persistentModelID
                    )
                )

                Text("reps")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                doubleField(
                    "+/-",
                    value: displayBodyWeightModifier,
                    width: 58,
                    keyboard: .numbersAndPunctuation,
                    focus: .bodyWeightModifier(
                        set.persistentModelID
                    )
                )

                unitLabel
            }

        case .time:
            durationFields()

        case .timeWeight:
            HStack(spacing: 5) {
                durationFields()

                doubleField(
                    "Weight",
                    value: displayWeight,
                    width: 56,
                    keyboard: .decimalPad,
                    focus: .weight(
                        set.persistentModelID
                    )
                )

                unitLabel
            }

        case .distanceTime:
            HStack(spacing: 5) {
                doubleField(
                    "Miles",
                    value: distanceBinding,
                    width: 58,
                    keyboard: .decimalPad,
                    focus: .distance(
                        set.persistentModelID
                    )
                )

                Text("mi")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("in")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                durationFields()
            }

        case .repsOnly:
            HStack(spacing: 5) {
                intField(
                    "Reps",
                    value: repsBinding,
                    width: 58,
                    focus: .reps(
                        set.persistentModelID
                    )
                )

                Text("reps")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    // MARK: - Unit Label

    private var unitLabel: some View {
        Text(unitSettings.unit.rawValue)
            .font(
                .system(
                    size: 11,
                    weight: .medium
                )
            )
            .foregroundStyle(.secondary)
            .fixedSize()
    }
}
