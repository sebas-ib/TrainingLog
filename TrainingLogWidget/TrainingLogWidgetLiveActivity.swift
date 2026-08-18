//
//  TrainingLogWidgetLiveActivity.swift
//  TrainingLogWidget
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TrainingLogWidgetLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in

            // MARK: - Lock Screen

            let isDone = context.state.isCompleted || context.isStale

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isDone ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: isDone ? "checkmark" : "timer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isDone ? .green : .accentColor)
                }

                if isDone {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest complete")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Tap to return to your workout")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Resting")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    ProgressView(
                        timerInterval: context.attributes.startedAt...context.state.endDate,
                        countsDown: false
                    )
                    .progressViewStyle(.circular)
                    .tint(.accentColor)
                    .frame(width: 34, height: 34)
                }
            }
            .padding(16)
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(.accentColor)

        } dynamicIsland: { context in

            // MARK: - Dynamic Island

            let isDone = context.state.isCompleted || context.isStale

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "timer")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isDone ? .green : .accentColor)

                        Text(isDone ? "Done" : "Resting")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isDone ? .green : .primary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if isDone {
                        Text("Tap to return")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !isDone {
                        ProgressView(
                            timerInterval: context.attributes.startedAt...context.state.endDate,
                            countsDown: false
                        )
                        .tint(.accentColor)
                        .padding(.top, 2)
                    }
                }
            } compactLeading: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "timer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isDone ? .green : .accentColor)
            } compactTrailing: {
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
            } minimal: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "timer")
                    .foregroundStyle(isDone ? .green : .accentColor)
            }
            .keylineTint(isDone ? .green : .accentColor)
        }
    }
}
