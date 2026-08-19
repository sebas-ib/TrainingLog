//
//  MuscleTarget.swift
//  TrainingLog
//

import Foundation

/// The specific muscle an exercise trains — finer-grained than
/// `MuscleGroup` (e.g. "Upper Chest" vs. just "Chest"), for exercises
/// where that distinction actually matters for programming (incline vs.
/// flat press, or which head of the delt a raise variation targets).
enum MuscleTarget: String, CaseIterable, Identifiable, Codable {
    case upperChest = "Upper Chest"
    case middleChest = "Middle Chest"
    case lowerChest = "Lower Chest"
    case frontDelts = "Front Delts"
    case sideDelts = "Side Delts"
    case rearDelts = "Rear Delts"
    case traps = "Traps"
    case lats = "Lats"
    case midBack = "Mid Back"
    case lowerBack = "Lower Back"
    case bicepsLongHead = "Biceps – Long Head"
    case bicepsShortHead = "Biceps – Short Head"
    case tricepsLongHead = "Triceps – Long Head"
    case tricepsLateralHead = "Triceps – Lateral Head"
    case tricepsMedialHead = "Triceps – Medial Head"
    case forearmFlexors = "Forearm Flexors"
    case forearmExtensors = "Forearm Extensors"
    case brachioradialis = "Brachioradialis"
    case abs = "Abs"
    case obliques = "Obliques"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case abductors = "Abductors"
    case adductors = "Adductors"
    case glutes = "Glutes"
    case calves = "Calves"

    var id: String { rawValue }

    /// The label actually shown in the UI. For most cases this is just
    /// `rawValue` — but the arm sub-heads carry a "Biceps –"/"Triceps –"
    /// prefix in their raw value purely to keep it unique from its
    /// counterpart in the sibling group (both Biceps and Triceps have a
    /// "Long Head"); showing that prefix is redundant everywhere it's
    /// actually displayed, since Biceps, Triceps, and Forearms are each
    /// their own `MuscleGroup`, so every list of these is already
    /// grouped or titled by which one you're looking at.
    var displayName: String {
        switch self {
        case .bicepsLongHead, .tricepsLongHead:
            return "Long Head"
        case .bicepsShortHead:
            return "Short Head"
        case .tricepsLateralHead:
            return "Lateral Head"
        case .tricepsMedialHead:
            return "Medial Head"
        case .forearmFlexors:
            return "Flexors"
        case .forearmExtensors:
            return "Extensors"
        default:
            return rawValue
        }
    }

    /// The broad category this specific muscle rolls up into — what
    /// drives `Exercise.muscleGroup` (and everything downstream of it:
    /// Progress-tab grouping, volume-by-muscle-group, icons) so that
    /// stays correct automatically as soon as an exercise's targets are
    /// set, without a second field to keep in sync by hand.
    var muscleGroup: MuscleGroup {
        switch self {
        case .upperChest, .middleChest, .lowerChest:
            return .chest
        case .frontDelts, .sideDelts, .rearDelts:
            return .shoulders
        case .traps, .lats, .midBack, .lowerBack:
            return .back
        case .bicepsLongHead, .bicepsShortHead:
            return .biceps
        case .tricepsLongHead, .tricepsLateralHead, .tricepsMedialHead:
            return .triceps
        case .forearmFlexors, .forearmExtensors, .brachioradialis:
            return .forearms
        case .abs, .obliques:
            return .core
        case .quads, .hamstrings, .abductors, .adductors, .glutes, .calves:
            return .legs
        }
    }
}
