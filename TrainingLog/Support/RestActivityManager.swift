//
//  RestActivityManager.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/16/26.
//
import ActivityKit
import Foundation

@MainActor
final class RestActivityManager {

    static let shared = RestActivityManager()

    private init() {}

    private var activity:
        Activity<RestActivityAttributes>?

    // MARK: - Start

    func start(duration: Int) {
        guard duration > 0 else {
            print("Rest Live Activity not started — duration was \(duration).")
            return
        }

        guard ActivityAuthorizationInfo()
            .areActivitiesEnabled else {
            print("Live Activities are disabled.")
            return
        }

        let startedAt = Date()

        let endDate = startedAt.addingTimeInterval(
            TimeInterval(duration)
        )

        let attributes = RestActivityAttributes(
            startedAt: startedAt,
            targetSeconds: duration
        )

        let state =
            RestActivityAttributes.ContentState(
                endDate: endDate
            )

        let content = ActivityContent(
            state: state,
            staleDate: endDate
        )

        // Hand off whatever activity we're currently tracking — running,
        // or merely lingering post-complete() — and clear our reference
        // to it up front. The hand-off is awaited *inside* the Task below
        // before the new request goes out, so this can't race the new
        // request into ActivityKit's concurrent-activity limit the way
        // calling end() (a separate, unawaited fire-and-forget) followed
        // immediately by Activity.request() could.
        let previousActivity = activity
        activity = nil

        Task {
            if let previousActivity {
                let endedState =
                    RestActivityAttributes.ContentState(
                        endDate: Date()
                    )

                let endedContent = ActivityContent(
                    state: endedState,
                    staleDate: nil
                )

                await previousActivity.end(
                    endedContent,
                    dismissalPolicy: .immediate
                )
            }

            do {
                activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )

                print("Rest Live Activity started.")
            } catch {
                print(
                    "Failed to start Rest Live Activity: \(error)"
                )
            }
        }
    }

    // MARK: - Update

    /// Pushes a new end date to the running activity — e.g. when the
    /// user nudges the rest target while resting. No-ops if there's no
    /// active activity.
    func update(endDate: Date) {
        guard let activity else {
            return
        }

        let state =
            RestActivityAttributes.ContentState(
                endDate: endDate
            )

        let content = ActivityContent(
            state: state,
            staleDate: endDate
        )

        Task {
            await activity.update(content)
        }
    }

    // MARK: - Complete

    /// Marks the activity as finished — the widget switches to a "Done"
    /// state the user can tap back into the app from — then lets it
    /// linger on the Lock Screen/Dynamic Island for a grace period before
    /// auto-dismissing, rather than vanishing instantly like end().
    ///
    /// Deliberately does *not* clear `activity` afterward: the Live
    /// Activity is still alive at the OS level for the whole linger
    /// window, and start() needs the reference to dismiss it immediately
    /// if a new rest timer begins before that window elapses. Clearing
    /// it here would let a same-window restart race the still-lingering
    /// activity into ActivityKit's concurrent-activity limit.
    func complete(lingerFor seconds: TimeInterval = 60) {
        guard let activity else {
            return
        }

        let state =
            RestActivityAttributes.ContentState(
                endDate: Date(),
                isCompleted: true
            )

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        Task {
            await activity.end(
                content,
                dismissalPolicy: .after(Date().addingTimeInterval(seconds))
            )
        }

        print("Rest Live Activity completed.")
    }

    // MARK: - End

    func end() {
        guard let activity else {
            return
        }

        let state =
            RestActivityAttributes.ContentState(
                endDate: Date()
            )

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        Task {
            await activity.end(
                content,
                dismissalPolicy: .immediate
            )
        }

        self.activity = nil

        print("Rest Live Activity ended.")
    }
}
