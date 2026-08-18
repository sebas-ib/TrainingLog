//
//  RestActivityAttributes.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//
import ActivityKit
import Foundation
 
struct RestActivityAttributes: ActivityAttributes {
 
    struct ContentState: Codable, Hashable {
        let endDate: Date
        var isCompleted: Bool = false
    }
 
    let startedAt: Date
    let targetSeconds: Int
}
 
