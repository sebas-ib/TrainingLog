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

            Section {
                Picker("History Shown", selection: Binding(
                    get: { unitSettings.consistencyWeeksToShow },
                    set: { unitSettings.consistencyWeeksToShow = $0 }
                )) {
                    Text("3 Months").tag(13)
                    Text("6 Months").tag(26)
                    Text("1 Year").tag(52)
                }
            } header: {
                Text("Consistency Graph")
            } footer: {
                Text("How far back the activity graph on the Progress tab reaches.")
            }
        }
        .navigationTitle("Settings")
        .toolbar(.hidden, for: .tabBar)
    }
}
