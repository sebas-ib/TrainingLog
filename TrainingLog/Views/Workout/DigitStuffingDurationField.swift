//
//  DigitStuffingDurationField.swift
//  TrainingLog
//

import SwiftUI
import UIKit

/// A calculator/stopwatch-style time field: it always displays a fully
/// zero-padded "M:SS" (or "MM:SS" past 9 minutes), and typing a digit
/// shifts the existing digits left and appends the new one at the end —
/// type "1", "3", "0" against "0:00" and you get "0:01" → "0:13" →
/// "1:30". Backspace does the reverse, shifting right and refilling
/// with a leading zero.
///
/// This is deliberately a `UIViewRepresentable` wrapping a real
/// `UITextField` rather than a plain SwiftUI `TextField`: digit-stuffing
/// entry doesn't have a meaningful cursor position — every keystroke
/// always affects the same fixed-width digit buffer regardless of where
/// the caret happens to be — and a `UITextFieldDelegate`'s
/// `shouldChangeCharactersIn` callback is the reliable way to intercept
/// each keystroke and drive that buffer directly, rather than trying to
/// diff an already-colon-formatted display string on every change.
struct DigitStuffingDurationField: UIViewRepresentable {
    @Binding var totalSeconds: Int
    var isEnabled: Bool
    var fontSize: CGFloat = 16
    var focusedField: FocusState<SetField?>.Binding
    var focusValue: SetField

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold)
        field.tintColor = .clear // no meaningful caret position to show
        field.delegate = context.coordinator
        field.text = Coordinator.format(totalSeconds)
        field.accessibilityLabel = "Duration"
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        uiView.isEnabled = isEnabled

        let formatted = Coordinator.format(totalSeconds)
        if uiView.text != formatted {
            uiView.text = formatted
            context.coordinator.resetDigits(to: totalSeconds)
        }

        let shouldBeFocused = focusedField.wrappedValue == focusValue
        if shouldBeFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !shouldBeFocused, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DigitStuffingDurationField
        private var digits: [Character]

        init(_ parent: DigitStuffingDurationField) {
            self.parent = parent
            self.digits = Self.digitsFor(parent.totalSeconds)
        }

        func resetDigits(to seconds: Int) {
            digits = Self.digitsFor(seconds)
        }

        static func format(_ totalSeconds: Int) -> String {
            let clamped = max(0, min(totalSeconds, 99 * 60 + 59))
            return String(format: "%d:%02d", clamped / 60, clamped % 60)
        }

        /// The four digits (MMSS) that make up `totalSeconds`, most
        /// significant first — the internal buffer this field edits.
        static func digitsFor(_ totalSeconds: Int) -> [Character] {
            let clamped = max(0, min(totalSeconds, 99 * 60 + 59))
            let combined = String(format: "%04d", (clamped / 60) * 100 + (clamped % 60))
            return Array(combined.suffix(4))
        }

        private func secondsFromDigits() -> Int {
            let combined = Int(String(digits)) ?? 0
            let minutes = combined / 100
            let seconds = min(combined % 100, 59)
            return minutes * 60 + seconds
        }

        private func commit(_ textField: UITextField) {
            let seconds = secondsFromDigits()
            textField.text = Self.format(seconds)
            if seconds != parent.totalSeconds {
                parent.totalSeconds = seconds
            }
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            if string.isEmpty {
                // Backspace — shift right, refill the front with a zero,
                // regardless of where the caret visually was.
                digits = ["0"] + digits.dropLast()
            } else {
                for character in string where character.isNumber {
                    digits = Array(digits.dropFirst()) + [character]
                }
            }
            commit(textField)
            return false // we've already written the formatted text ourselves
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.focusedField.wrappedValue = parent.focusValue
            // Digit entry doesn't depend on caret position, but leaving
            // it mid-string looks like a stray blinking line — park it
            // at the end.
            DispatchQueue.main.async {
                let end = textField.endOfDocument
                textField.selectedTextRange = textField.textRange(from: end, to: end)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.focusedField.wrappedValue == parent.focusValue {
                parent.focusedField.wrappedValue = nil
            }
        }
    }
}
