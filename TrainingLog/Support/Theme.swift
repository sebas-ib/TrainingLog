//
//  Theme.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/13/26.
//
import SwiftUI

enum Theme {
    static let accent = Color(red: 0.95, green: 0.42, blue: 0.20)
    
    static func title(_ style: Font.TextStyle = .title3, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
    
    static func sectionHeader() -> Font {
        .system(.subheadline, design: .rounded, weight: .bold)
    }
}
