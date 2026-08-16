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

final class UnitSettings: ObservableObject {
    @AppStorage("weightUnit") var unitRawValue: String = WeightUnit.lbs.rawValue
    @AppStorage("consistencyWeeksToShow") var consistencyWeeksToShow: Int = 12
    
    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRawValue) ?? .lbs }
        set { unitRawValue = newValue.rawValue }
    }
}
