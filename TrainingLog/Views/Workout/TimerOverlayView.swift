//
//  TimerOverlayView.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//

import SwiftUI
import AudioToolbox

struct TimerOverlayView: View {

    enum Mode {
        case restCountdown
        case setFocusStopwatch

        var adjustStep: Int {
            switch self {
            case .restCountdown: return 15
            case .setFocusStopwatch: return 5
            }
        }

        var targetLabel: String {
            switch self {
            case .restCountdown: return "Rest"
            case .setFocusStopwatch: return "Target"
            }
        }

        /// Used in accessibility labels, e.g. "Pause rest timer" / "Pause timer".
        var accessibilityContext: String {
            switch self {
            case .restCountdown: return "rest timer"
            case .setFocusStopwatch: return "timer"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    let timer: Timer
    let mode: Mode
    /// Identifies the set being timed, e.g. "Plank · Set 2" — shown in
    /// the Live Activity while `mode == .setFocusStopwatch`. Unused for
    /// `.restCountdown`.
    var label: String = ""

    private var displaySeconds: Int {
        switch mode {
        case .restCountdown:
            return timer.remainingSeconds
        case .setFocusStopwatch:
            return timer.elapsedSeconds
        }
    }

    private var progress: Double {
        guard timer.targetSeconds > 0 else { return 0 }
        return min(1, Double(timer.elapsedSeconds) / Double(timer.targetSeconds))
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                closeButton
                Spacer()
                dial
                targetControls
                Spacer()
                controls
            }
        }
    }

    // MARK: - Close

    private var closeButton: some View {
        HStack {
            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close \(mode.accessibilityContext)")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Dial

    private var dial: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 14)
                .frame(width: 260, height: 260)

            if timer.targetSeconds > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timer.hasCrossedTarget ? Color.green : Color(Theme.accent),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    // Start at 12 o'clock and fill clockwise instead of the
                    // default 3 o'clock start.
                    .rotationEffect(.degrees(-90))
                    // Matches the ~200ms poll cadence on Timer so the fill
                    // tracks smoothly rather than stepping visibly.
                    .animation(.linear(duration: 0.2), value: progress)
            }

            Text(Self.formattedDuration(displaySeconds))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(timer.hasCrossedTarget ? .green : .primary)
                .contentTransition(.numericText())
                .animation(.default, value: displaySeconds)
        }
    }

    // MARK: - Target controls

    @ViewBuilder
    private var targetControls: some View {
        if timer.targetSeconds > 0 {
            HStack(spacing: 18) {
                stepButton(systemName: "minus") {
                    adjustTarget(by: -mode.adjustStep)
                }
                .disabled(mode == .restCountdown && timer.targetSeconds <= mode.adjustStep)

                Text("\(mode.targetLabel) \(Self.formattedDuration(timer.targetSeconds))")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                stepButton(systemName: "plus") {
                    adjustTarget(by: mode.adjustStep)
                }
            }
        } else if mode == .setFocusStopwatch {
            // Rest timers always start with a target; only the set-focus
            // stopwatch can be running with no target set yet.
            Button {
                timer.adjustTarget(by: 30)
            } label: {
                Text("Set a target")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func adjustTarget(by delta: Int) {
        if mode == .restCountdown {
            timer.adjustRestTarget(by: delta)
        } else {
            timer.adjustTarget(by: delta)
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 24) {
            Button {
                if mode == .restCountdown {
                    timer.resetRestCountdown()
                } else {
                    timer.resetSetTimer()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset \(mode.accessibilityContext)")

            Button {
                if timer.isRunning {
                    if mode == .restCountdown {
                        timer.pauseRestCountdown()
                    } else {
                        timer.pauseSetTimer()
                    }
                } else {
                    if mode == .restCountdown {
                        timer.startRestCountdown()
                    } else {
                        timer.startSetTimer(label: label)
                    }
                }
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 84, height: 84)
                    .background(
                        Circle().fill(timer.isRunning ? Color.orange : Color(Theme.accent))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                timer.isRunning ? "Pause \(mode.accessibilityContext)" : "Start \(mode.accessibilityContext)"
            )
        }
    }

    // MARK: - Formatting

    private static func formattedDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
