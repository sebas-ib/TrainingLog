//
//  SettingsView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
        
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
        }
        .navigationTitle("Settings")
    }
}
