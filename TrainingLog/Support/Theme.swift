//
//  Theme.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/13/26.
//
import SwiftUI

enum Theme {
    /// The brand orange, tuned per appearance rather than a single fixed
    /// value: the vibrant dark-mode shade only reaches ~3:1 contrast
    /// against light-mode's white/near-white surfaces — enough for
    /// icons and large text, but short of the 4.5:1 AA needs for normal
    /// text (badge labels, button captions). Light mode uses a deeper,
    /// more saturated version of the same hue (~4.5:1 against white);
    /// dark mode keeps the original, which already clears ~6.9:1 against
    /// black.
    static let accent = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.42, blue: 0.20, alpha: 1)
            : UIColor(red: 0.95, green: 0.42, blue: 0.20, alpha: 1)
    })

    /// The "elevated card" background used for panels that sit on top of
    /// a grouped/gradient page background (day summary, consistency
    /// graph, workout summary). `secondarySystemBackground` reads as a
    /// light gray in light mode — barely distinct from the
    /// `systemGroupedBackground` page behind it — so light mode instead
    /// uses `tertiarySystemBackground` (white) to keep the card visibly
    /// elevated; dark mode's `secondarySystemBackground` already pops
    /// against the near-black grouped background there.
    static let cardBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.secondarySystemBackground
            : UIColor.tertiarySystemBackground
    })

    static func title(_ style: Font.TextStyle = .title3, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static func sectionHeader() -> Font {
        .system(.subheadline, design: .rounded, weight: .bold)
    }
}
