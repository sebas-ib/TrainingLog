//
//  UnitPreference.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation
import SwiftUI
import Combine

enum WeightUnit: String, CaseIterable {
    case lbs = "lbs"
    case kg = "kg"

    func convert(fromLbs value: Double) -> Double {
        switch self {
        case .lbs: return value
        case .kg: return value * 0.453592
        }
    }

    func convertToLbs(_ value: Double) -> Double {
        switch self {
        case .lbs: return value
        case .kg: return value / 0.453592
        }
    }
}

/// Distance doesn't get its own setting — it follows the weight unit.
/// Someone who's set weight to kg is almost certainly expecting distance
/// in km too, and a separate toggle for it would mostly just be a way to
/// end up with mismatched units by accident.
enum DistanceUnit: String, CaseIterable {
    case miles = "mi"
    case kilometers = "km"

    func convert(fromMiles value: Double) -> Double {
        switch self {
        case .miles: return value
        case .kilometers: return value * 1.609344
        }
    }

    func convertToMiles(_ value: Double) -> Double {
        switch self {
        case .miles: return value
        case .kilometers: return value / 1.609344
        }
    }
}

final class UnitSettings: ObservableObject {
    @AppStorage("weightUnit") var unitRawValue: String = WeightUnit.lbs.rawValue
    @AppStorage("consistencyWeeksToShow") var consistencyWeeksToShow: Int = 12

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRawValue) ?? .lbs }
        set { unitRawValue = newValue.rawValue }
    }

    var distanceUnit: DistanceUnit {
        unit == .lbs ? .miles : .kilometers
    }
}
