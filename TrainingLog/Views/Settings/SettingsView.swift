//
//  SettingsView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    
    private let weekOptions = [52, 26, 12, 8, 4]
    
    var body: some View {
        Form {
            Section("Units") {
                Picker("Weight Unit", selection: Binding(
                    get: { unitSettings.unit },
                    set: { unitSettings.unit = $0 }
                )) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Consistency Graph") {
                Picker("Weeks to Show", selection: $unitSettings.consistencyWeeksToShow) {
                    ForEach(weekOptions, id: \.self) { weeks in
                        Text("\(weeks) weeks").tag(weeks)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
