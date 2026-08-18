//
//  DigitStuffingDurationField.swift
//  TrainingLog
//

import SwiftUI

/// A calculator/stopwatch-style time field: it always displays a fully
/// zero-padded "M:SS" (or "MM:SS" past 9 minutes), and typing a digit
/// shifts the existing digits left and appends the new one at the end —
/// type "1", "3", "0" against "0:00" and you get "0:01" → "0:13" →
/// "1:30". Backspace does the reverse, shifting right and refilling
/// with a leading zero.
///
/// This used to be a `UIViewRepresentable` wrapping a real `UITextField`,
/// manually bridging its first-responder status to `focusedField`. That
/// bridge was the actual bug: `becomeFirstResponder()`/
/// `resignFirstResponder()` synchronously fire
/// `textFieldDidBeginEditing`/`textFieldDidEndEditing`, which write back
/// to the very `focusedField` binding that had just been read to decide
/// whether to call them — a read-then-write-in-the-same-pass loop that
/// showed up as "AttributeGraph: cycle detected" and, in practice, could
/// drop the keyboard after a single keystroke. A plain `TextField` with
/// native `.focused()` — the same mechanism every other field in this
/// row already uses without issue — has no such bridge to desync.
///
/// The one thing native `TextField` doesn't give us is a reliable
/// "which digit was just typed" the way `shouldChangeCharactersIn` did
/// regardless of caret position. `insertedDigit(old:new:)` below gets
/// the same position-independent guarantee a different way: for a
/// single-character insertion, the inserted character is whatever sits
/// where the old and new strings first diverge — true no matter where
/// the caret was.
struct DigitStuffingDurationField: View {
    @Binding var totalSeconds: Int
    var isEnabled: Bool
    var fontSize: CGFloat = 16
    var focusedField: FocusState<SetField?>.Binding
    var focusValue: SetField

    /// The one piece of state this field owns — the 4-digit MMSS buffer.
    /// The displayed/editable string is derived from it on demand rather
    /// than tracked as its own separately-synced `@State`.
    @State private var digits: [Character]

    init(
        totalSeconds: Binding<Int>,
        isEnabled: Bool,
        fontSize: CGFloat = 16,
        focusedField: FocusState<SetField?>.Binding,
        focusValue: SetField
    ) {
        self._totalSeconds = totalSeconds
        self.isEnabled = isEnabled
        self.fontSize = fontSize
        self.focusedField = focusedField
        self.focusValue = focusValue
        self._digits = State(initialValue: Self.digitsFor(totalSeconds.wrappedValue))
    }

    /// The field's displayed/editable text, derived from `digits`. Get/set
    /// `Binding` rather than a separate `@State` string kept in sync via
    /// `.onChange` — matches how SetRowView already binds its other
    /// fields (`durationBinding`, `displayWeight`, ...), and means the
    /// setter only ever runs on a genuine edit instead of needing to
    /// filter out its own echoed writes.
    private var text: Binding<String> {
        Binding(
            get: { Self.format(digits: digits) },
            set: { newValue in handleTextChange(to: newValue) }
        )
    }

    var body: some View {
        TextField("0:00", text: text)
            .keyboardType(.numberPad)
            .textFieldStyle(.plain)
            .font(.system(size: fontSize, weight: .semibold))
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .disabled(!isEnabled)
            .focused(focusedField, equals: focusValue)
            .accessibilityLabel("Duration")
            .onChange(of: totalSeconds) { _, newValue in
                syncFromExternal(newValue)
            }
    }

    /// Interprets a raw text-field edit as either "one digit typed" or
    /// "backspace" and updates the digit buffer accordingly.
    private func handleTextChange(to newValue: String) {
        let oldValue = Self.format(digits: digits)
        guard newValue != oldValue else { return }

        if newValue.count < oldValue.count {
            // Backspace — shift right, refill the front with a zero,
            // regardless of where the caret visually was.
            digits = ["0"] + digits.dropLast()
        } else if let inserted = Self.insertedDigit(old: oldValue, new: newValue) {
            digits = Array(digits.dropFirst()) + [inserted]
        } else {
            // Couldn't confidently interpret the edit (e.g. a paste, or
            // a mid-string replacement) — digit-stuffing doesn't have a
            // meaningful notion of "replace this character," so `digits`
            // is left untouched; the field just shows its last valid
            // value again instead of guessing.
            return
        }

        let seconds = Self.seconds(from: digits)
        if seconds != totalSeconds {
            totalSeconds = seconds
        }
    }

    /// Keeps the field in sync with `totalSeconds` changing from outside
    /// (the timer ticking, "Fill with previous," Clear) without
    /// clobbering in-progress typing that already matches.
    private func syncFromExternal(_ seconds: Int) {
        guard seconds != Self.seconds(from: digits) else { return }
        digits = Self.digitsFor(seconds)
    }

    /// The single character that turns `old` into `new`, assuming
    /// exactly one character was inserted somewhere — found as wherever
    /// the two strings first diverge, which holds regardless of caret
    /// position. Returns nil if the edit doesn't look like a clean
    /// single-character insertion (e.g. `new` isn't exactly one longer).
    private static func insertedDigit(old: String, new: String) -> Character? {
        guard new.count == old.count + 1 else { return nil }

        let oldChars = Array(old)
        let newChars = Array(new)

        var i = 0
        while i < oldChars.count, i < newChars.count, oldChars[i] == newChars[i] {
            i += 1
        }

        guard i < newChars.count, newChars[i].isNumber else { return nil }
        return newChars[i]
    }

    /// The four digits (MMSS) that make up `totalSeconds`, most
    /// significant first — the internal buffer this field edits.
    private static func digitsFor(_ totalSeconds: Int) -> [Character] {
        let clamped = max(0, min(totalSeconds, 99 * 60 + 59))
        let combined = String(format: "%04d", (clamped / 60) * 100 + (clamped % 60))
        return Array(combined.suffix(4))
    }

    private static func seconds(from digits: [Character]) -> Int {
        let combined = Int(String(digits)) ?? 0
        let minutes = combined / 100
        let seconds = min(combined % 100, 59)
        return minutes * 60 + seconds
    }

    private static func format(digits: [Character]) -> String {
        DurationFormatting.minutesSeconds(seconds(from: digits))
    }
}
