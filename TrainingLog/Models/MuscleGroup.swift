//
//  MuscleGroup.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//


import Foundation

enum MuscleGroup: String, CaseIterable, Codable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case core = "Core"
    case other = "Other"

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .legs: return "figure.strengthtraining.functional"
        case .shoulders: return "figure.arms.open"
        case .biceps: return "dumbbell.fill"
        case .triceps: return "figure.boxing"
        case .forearms: return "hand.raised.fill"
        case .core: return "figure.core.training"
        case .other: return "questionmark.circle"
        }
    }
}
