//
//  Timer.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//
import UIKit
import AudioToolbox

// MARK: - Timer

/// Generic play/pause/reset timer with target tracking and a completion
/// cue. Knows nothing about ExerciseSet or SwiftData — a consumer wires
/// `onChange` to mirror `elapsedSeconds` wherever it needs to live (a
/// model field, or nowhere at all for an ephemeral rest timer). Reused by
/// both the per-set duration timer below and, e.g., a between-sets rest
/// timer — a rest UI just displays `targetSeconds - elapsedSeconds`
/// instead of `elapsedSeconds` directly; the engine itself only ever
/// counts up.
@Observable
final class Timer {
    private(set) var isRunning = false
    private(set) var elapsedSeconds: Int
    var targetSeconds: Int
    private(set) var hasCrossedTarget: Bool

    private var baseSeconds: Int
    private var startDate: Date?
    private var tickTask: Task<Void, Never>?

    /// Fires whenever elapsedSeconds changes — ticking, reset, or a pause.
    /// This is the hook a consumer uses to mirror the value somewhere
    /// durable or debounce a save. Re-supply per call site if it closes
    /// over view-specific state (e.g. @Environment(\.modelContext)).
    var onChange: (Int) -> Void = { _ in }

    /// Fires exactly once per run, the instant elapsed reaches target.
    /// Defaults to a haptic + soft system sound; override for different
    /// completion behavior (e.g. auto-advancing to the next set).
    var onTargetCrossed: () -> Void = {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        // System sound rather than AVAudioPlayer — respects the silent
        // switch and needs no audio session setup.
        AudioServicesPlaySystemSound(1057)
    }
    
    var remainingSeconds: Int {
        max(0, targetSeconds - elapsedSeconds)
    }

    init(initialSeconds: Int = 0, targetSeconds: Int = 0) {
        self.elapsedSeconds = initialSeconds
        self.baseSeconds = initialSeconds
        self.targetSeconds = targetSeconds
        self.hasCrossedTarget = targetSeconds > 0 && initialSeconds >= targetSeconds
    }

    func start() {
        guard !isRunning else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Resume from whatever elapsedSeconds currently holds, so a paused
        // timer (or a manually-set starting value) picks up correctly.
        baseSeconds = elapsedSeconds
        startDate = Date()
        isRunning = true
        hasCrossedTarget = targetSeconds > 0 && elapsedSeconds >= targetSeconds

        // Keep the screen awake while actively timing so the lock screen
        // doesn't cut off the set or the rest period.
        IdleTimerCoordinator.acquire()

        tickTask?.cancel()
        tickTask = Task { [weak self] in
            // Polls at 200ms rather than waiting a full 1s so a
            // slightly-late poll under load costs ~100-200ms instead of a
            // whole missed second. tick() only fires onChange when the
            // displayed integer-second value actually changes.
            while let self, !Task.isCancelled {
                self.tick()
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    func pause() {
        guard isRunning else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        stopTicking()
        onChange(elapsedSeconds)
    }

    /// Clears back to `newValue` (0 by default) — distinct from pause(),
    /// which keeps the current value.
    func reset(to newValue: Int = 0) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        stopTicking()
        hasCrossedTarget = false
        elapsedSeconds = newValue
        baseSeconds = newValue
        onChange(elapsedSeconds)
    }

    /// Called from the owning view's onDisappear. Same effect as pause()
    /// but without the haptic, since the user didn't tap anything.
    func suspend() {
        guard isRunning else { return }
        stopTicking()
    }

    /// Reconciles the engine's internal elapsed value with an external
    /// change to whatever `onChange` mirrors it into (e.g. the user
    /// directly editing a duration field, or "copy previous" writing a
    /// new value into the model). Unlike reset(to:), this doesn't fire
    /// a haptic or call `onChange` back out — the caller already is the
    /// source of truth for the value being synced in, and re-invoking
    /// `onChange` would just write the same value back.
    ///
    /// No-ops while running: start() reads elapsedSeconds/baseSeconds
    /// as its resume point, and the ticking loop owns those values
    /// while active, so an external write during that window would
    /// itself be the stale one.
    func syncElapsed(to newValue: Int) {
        guard !isRunning else { return }
        elapsedSeconds = newValue
        baseSeconds = newValue
        hasCrossedTarget = targetSeconds > 0 && elapsedSeconds >= targetSeconds
    }

    func adjustTarget(by delta: Int) {
        targetSeconds = max(0, targetSeconds + delta)
        hasCrossedTarget = targetSeconds > 0 && elapsedSeconds >= targetSeconds
    }

    private func stopTicking() {
        let wasRunning = isRunning
        isRunning = false
        startDate = nil
        tickTask?.cancel()
        tickTask = nil
        if wasRunning {
            IdleTimerCoordinator.release()
        }
    }

    private func tick() {
        guard let startDate else { return }

        let elapsed = Int(Date().timeIntervalSince(startDate))
        let newValue = baseSeconds + max(0, elapsed)

        guard newValue != elapsedSeconds else { return }
        elapsedSeconds = newValue

        if targetSeconds > 0, !hasCrossedTarget, newValue >= targetSeconds {
            hasCrossedTarget = true
            onTargetCrossed()
        }

        onChange(newValue)
    }

    deinit {
        // Thread-safety of touching UIApplication.shared here isn't
        // guaranteed, so this only cancels the loop. suspend() (called
        // from onDisappear) is what reliably clears isIdleTimerDisabled
        // during normal use.
        tickTask?.cancel()
    }
}
