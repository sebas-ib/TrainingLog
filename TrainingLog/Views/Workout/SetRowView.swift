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
    case duration(PersistentIdentifier)
    case distance(PersistentIdentifier)
}

extension SetField {
    /// The ordered sequence of input fields a set of this logging type
    /// presents, in the order they should be visited. Drives the
    /// keyboard's "next field" arrow, both for hopping within a row and
    /// (via the first element) for jumping into the next set's first
    /// field.
    static func sequence(for set: ExerciseSet, loggingType: ExerciseLoggingType) -> [SetField] {
        let id = set.persistentModelID
        switch loggingType {
        case .weightReps:
            return [.reps(id), .weight(id)]
        case .bodyweightReps:
            return [.reps(id), .bodyWeightModifier(id)]
        case .time:
            return [.duration(id)]
        case .timeWeight:
            return [.duration(id), .weight(id)]
        case .distanceTime:
            return [.distance(id), .duration(id)]
        case .repsOnly:
            return [.reps(id)]
        }
    }

    /// The set this field belongs to — lets a single, screen-level
    /// keyboard toolbar look up which set/exercise is being edited
    /// without every row needing its own toolbar.
    var setID: PersistentIdentifier {
        switch self {
        case .reps(let id), .weight(let id), .bodyWeightModifier(let id),
             .duration(let id), .distance(let id):
            return id
        }
    }
}

// MARK: - Set Row

struct SetRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var unitSettings: UnitSettings

    @Bindable var set: ExerciseSet

    let loggingType: ExerciseLoggingType
    let exerciseName: String
    var focusedField: FocusState<SetField?>.Binding
    var previousSet: ExerciseSet?

    /// Supplied by `SetTimerStore` rather than owned as `@State` here —
    /// a row's `@State` is discarded when `List` recycles it off screen,
    /// which used to stop a running set timer mid-set just because the
    /// user scrolled. See `SetTimerStore` for the full story.
    let timer: Timer

    @Binding var saveError: Error?

    @State private var pendingSave: DispatchWorkItem?
    @State private var hasAppeared = false
    @State private var showFocusMode = false

    // MARK: - Saving

    private func scheduleSave() {
        pendingSave?.cancel()

        let work = DispatchWorkItem {
            modelContext.save(reportingTo: $saveError)
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
        modelContext.save(reportingTo: $saveError)
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

    private var displayDistance: Binding<Double> {
        Binding(
            get: {
                unitSettings.distanceUnit.convert(fromMiles: set.distance)
            },
            set: { newValue in
                set.distance = max(
                    0,
                    unitSettings.distanceUnit.convertToMiles(newValue)
                )
                scheduleSave()
            }
        )
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { set.durationSeconds },
            set: { newValue in
                set.durationSeconds = max(0, newValue)
                timer.syncElapsed(to: set.durationSeconds)
                scheduleSave()
            }
        )
    }

    // MARK: - Step Sizes

    /// Plates typically move in 5 lb / 2.5 kg increments — close enough
    /// for dumbbells and machines too, and still fully overridable by
    /// typing an exact number.
    private var weightStep: Double {
        unitSettings.unit == .lbs ? 5 : 2.5
    }

    private var distanceStep: Double {
        0.1
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
                DurationFormatting.minutesSeconds(previousSet.durationSeconds)
            )

        case .timeWeight:
            let weight = unitSettings.unit.convert(
                fromLbs: previousSet.weight
            )

            parts.append(
                "\(DurationFormatting.minutesSeconds(previousSet.durationSeconds)) @ \(String(format: "%.0f", weight)) \(unitSettings.unit.rawValue)"
            )

        case .distanceTime:
            let distance = unitSettings.distanceUnit.convert(
                fromMiles: previousSet.distance
            )

            parts.append(
                "\(String(format: "%.2f", distance)) \(unitSettings.distanceUnit.rawValue) in \(DurationFormatting.minutesSeconds(previousSet.durationSeconds))"
            )

        case .repsOnly:
            parts.append("\(previousSet.reps) reps")
        }

        if previousSet.takenToFailure {
            parts.append("Failure")
        }

        return parts.joined(separator: " · ")
    }

    /// Identifies this set's timer in the Live Activity / Dynamic Island
    /// while the app is backgrounded, e.g. "Plank · Set 2".
    private var timerLabel: String {
        "\(exerciseName) · Set \(set.order)"
    }

    private var isDurationBasedType: Bool {
        switch loggingType {
        case .time, .timeWeight, .distanceTime:
            return true
        case .weightReps, .bodyweightReps, .repsOnly:
            return false
        }
    }

    // MARK: - Row Background

    private var backgroundColor: Color {
        colorScheme == .light ? Color(.secondarySystemBackground) : Color(.tertiarySystemBackground)
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

            // Both moved off .padding(.leading, 36) on themselves and onto
            // this shared HStack — previously each carried its own 36pt
            // leading padding, so together they doubled up instead of
            // sharing one aligned offset.
            HStack(spacing: 4) {
                fillOrClearButton

                if isDurationBasedType {
                    targetAdjuster
                }
            }
            .padding(.leading, 36)
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
        .onDisappear {
            // Flushes pending edits, but deliberately does *not* suspend
            // the timer: `List` fires this whenever the row scrolls out
            // of view, and a set that's actively being timed should keep
            // running. `SetTimerStore.suspendAll()`, on leaving the
            // workout screen, is what stops them now.
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

            timer.onChange = { seconds in
                set.durationSeconds = seconds
                scheduleSave()
            }
        }
        .fullScreenCover(isPresented: $showFocusMode) {
            TimerOverlayView(
                timer: timer,
                mode: .setFocusStopwatch,
                label: timerLabel
            )
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
                        : Color(backgroundColor)
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

    // MARK: - Fill / Clear

    /// Toggles between "Fill with previous" (when this set's inputs are
    /// still at their empty defaults) and "Clear" (once anything's been
    /// entered — whether by auto-fill, this button, or typing). A set
    /// that's just been created is auto-filled from the previous
    /// session's matching set already, so this reads as "Clear" from the
    /// start in the common case, and flips back to "Fill with previous"
    /// once cleared.
    @ViewBuilder
    private var fillOrClearButton: some View {
        if set.hasEmptyValues(loggingType: loggingType) {
            if let previousHint {
                previousSetButton(hint: previousHint)
            }
        } else {
            clearSetButton
        }
    }

    private func previousSetButton(hint: String) -> some View {
        Button {
            copyFromPrevious()
        } label: {
            HStack(spacing: 5) {
                Image(
                    systemName: "arrow.uturn.backward"
                )
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)

                Text(hint)
                    .font(
                        .system(
                            size: 11,
                            weight: .medium
                        )
                    )
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        Color(Theme.accent)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Fill with previous set: \(hint)"
        )
        .accessibilityHint(
            "Fills this set with the previous set's values"
        )
    }

    private var clearSetButton: some View {
        Button {
            clearSet()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))

                Text("Clear")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(backgroundColor))
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Clear set")
        .accessibilityHint(
            "Removes the values entered for this set"
        )
    }

    // MARK: - Target Adjuster

    private var targetAdjuster: some View {
        HStack {
            Button {
                timer.adjustTarget(by: -5)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle().fill(Color(backgroundColor))
                    )
            }
            .buttonStyle(.plain)
            .disabled(timer.targetSeconds == 0)

            Text(
                timer.targetSeconds > 0
                    ? "Target \(DurationFormatting.minutesSeconds(timer.targetSeconds))"
                    : "No target"
            )
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .frame(minWidth: 78, alignment: .center)

            Button {
                timer.adjustTarget(by: 5)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle().fill(Color(backgroundColor))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Copy Previous / Clear

    private func copyFromPrevious() {
        guard let previousSet else {
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(
            .spring(response: 0.3, dampingFraction: 0.7)
        ) {
            set.copyValues(from: previousSet, loggingType: loggingType)
        }

        // Copying a duration-based type bypasses the duration field's own
        // binding, so the stopwatch engine needs the same sync that
        // binding does — otherwise starting the timer afterward would
        // silently discard the copied value.
        if isDurationBasedType {
            timer.syncElapsed(to: set.durationSeconds)
        }

        saveNow()
    }

    private func clearSet() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(
            .spring(response: 0.3, dampingFraction: 0.7)
        ) {
            set.clearValues(loggingType: loggingType)
        }

        if isDurationBasedType {
            timer.syncElapsed(to: set.durationSeconds)
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

    // MARK: - Stepper Fields

    /// A number field flanked by small +/- buttons — typing is still
    /// available for exact or big-jump values, but small week-to-week
    /// adjustments (a rep, a plate) don't need the keyboard at all.
    private func steppedIntField(
        _ placeholder: String,
        value: Binding<Int>,
        step: Int,
        minValue: Int = 0,
        fieldWidth: CGFloat,
        focus: SetField
    ) -> some View {
        HStack(spacing: 2) {
            miniStepButton(systemName: "minus") {
                value.wrappedValue = max(minValue, value.wrappedValue - step)
            }

            intField(placeholder, value: value, width: fieldWidth, focus: focus)

            miniStepButton(systemName: "plus") {
                value.wrappedValue += step
            }
        }
    }

    private func steppedDoubleField(
        _ placeholder: String,
        value: Binding<Double>,
        step: Double,
        minValue: Double? = 0,
        fieldWidth: CGFloat,
        keyboard: UIKeyboardType,
        focus: SetField
    ) -> some View {
        HStack(spacing: 2) {
            miniStepButton(systemName: "minus") {
                let next = value.wrappedValue - step
                value.wrappedValue = minValue.map { Swift.max($0, next) } ?? next
            }

            doubleField(placeholder, value: value, width: fieldWidth, keyboard: keyboard, focus: focus)

            miniStepButton(systemName: "plus") {
                value.wrappedValue += step
            }
        }
    }

    private func miniStepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color(backgroundColor)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Duration Field

    private var durationField: some View {
        DigitStuffingDurationField(
            totalSeconds: durationBinding,
            isEnabled: !timer.isRunning,
            focusedField: focusedField,
            focusValue: .duration(set.persistentModelID)
        )
        .frame(width: 66, height: 34)
    }

    // MARK: - Timer Controls

    private var timerControls: some View {
        HStack(spacing: 6) {
            Button {
                timer.isRunning ? timer.pauseSetTimer() : timer.startSetTimer(label: timerLabel)
            } label: {
                Image(
                    systemName: timer.isRunning
                        ? "pause.fill"
                        : "play.fill"
                )
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(
                            timer.isRunning
                                ? Color.orange
                                : Color(Theme.accent)
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                timer.isRunning ? "Pause timer" : "Start timer"
            )

            Button {
                timer.resetSetTimer()
            } label: {
                // arrow.counterclockwise instead of a stop square — the
                // action clears the field back to 0, so the icon should
                // read as "reset," not "stop and keep this value."
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(Color(backgroundColor))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!timer.isRunning && set.durationSeconds == 0)
            .accessibilityLabel("Reset timer")

            Button {
                showFocusMode = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(Color(backgroundColor))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open full-screen timer")
        }
    }

    // MARK: - Fields By Type

    @ViewBuilder
    private var fieldsForType: some View {
        switch loggingType {

        case .weightReps:
            HStack(spacing: 5) {
                steppedIntField(
                    "Reps",
                    value: repsBinding,
                    step: 1,
                    fieldWidth: 34,
                    focus: .reps(
                        set.persistentModelID
                    )
                )

                Text("×")
                    .foregroundStyle(.secondary)

                steppedDoubleField(
                    "Weight",
                    value: displayWeight,
                    step: weightStep,
                    fieldWidth: 46,
                    keyboard: .decimalPad,
                    focus: .weight(
                        set.persistentModelID
                    )
                )

                unitLabel
            }

        case .bodyweightReps:
            HStack(spacing: 5) {
                steppedIntField(
                    "Reps",
                    value: repsBinding,
                    step: 1,
                    fieldWidth: 34,
                    focus: .reps(
                        set.persistentModelID
                    )
                )

                Text("reps")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                steppedDoubleField(
                    "+/-",
                    value: displayBodyWeightModifier,
                    step: weightStep,
                    minValue: nil,
                    fieldWidth: 40,
                    keyboard: .numbersAndPunctuation,
                    focus: .bodyWeightModifier(
                        set.persistentModelID
                    )
                )

                unitLabel
            }

        case .time:
            HStack(spacing: 6) {
                durationField
                timerControls
            }

        case .timeWeight:
            HStack(spacing: 5) {
                durationField
                timerControls

                steppedDoubleField(
                    "Weight",
                    value: displayWeight,
                    step: weightStep,
                    fieldWidth: 44,
                    keyboard: .decimalPad,
                    focus: .weight(
                        set.persistentModelID
                    )
                )

                unitLabel
            }

        case .distanceTime:
            HStack(spacing: 5) {
                steppedDoubleField(
                    "Distance",
                    value: displayDistance,
                    step: distanceStep,
                    fieldWidth: 42,
                    keyboard: .decimalPad,
                    focus: .distance(
                        set.persistentModelID
                    )
                )

                Text(unitSettings.distanceUnit.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("in")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                durationField
                timerControls
            }

        case .repsOnly:
            HStack(spacing: 5) {
                steppedIntField(
                    "Reps",
                    value: repsBinding,
                    step: 1,
                    fieldWidth: 40,
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
