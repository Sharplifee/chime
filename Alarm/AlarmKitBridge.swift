import Foundation
import SwiftUI
import AppIntents
#if canImport(AlarmKit)
import AlarmKit

struct ChimeMetadata: AlarmMetadata {
    init() {}
}

/// Stop button on the alerting UI.
struct ChimeStopIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop"
    @Parameter(title: "alarmID") var alarmID: String

    init() {}
    init(alarmID: UUID) { self.alarmID = alarmID.uuidString }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.stop(id: id)
        }
        return .result()
    }
}

/// Snooze button on the alerting UI.
struct ChimeSnoozeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Snooze"
    @Parameter(title: "alarmID") var alarmID: String

    init() {}
    init(alarmID: UUID) { self.alarmID = alarmID.uuidString }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.countdown(id: id)
        }
        return .result()
    }
}

enum AlarmKitBridge {

    private static func attributes(title: String) -> AlarmAttributes<ChimeMetadata> {
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: .stopButton,
            secondaryButton: .snoozeButton,
            secondaryButtonBehavior: .countdown
        )
        let countdown = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: title),
            pauseButton: .pauseButton
        )
        let paused = AlarmPresentation.Paused(
            title: "Paused",
            resumeButton: .resumeButton
        )
        return AlarmAttributes(
            presentation: AlarmPresentation(alert: alert, countdown: countdown, paused: paused),
            metadata: ChimeMetadata(),
            tintColor: Color.orange
        )
    }

    /// Timer: counts down `duration` from now, then alerts.
    static func scheduleCountdown(id: UUID,
                                  duration: TimeInterval,
                                  label: String,
                                  sound: String) async throws {
        let config = AlarmManager.AlarmConfiguration(
            countdownDuration: Alarm.CountdownDuration(preAlert: duration, postAlert: 5 * 60),
            schedule: nil,
            attributes: attributes(title: label),
            stopIntent: ChimeStopIntent(alarmID: id),
            secondaryIntent: ChimeSnoozeIntent(alarmID: id),
            sound: .default
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
    }

    /// Alarm: fixed wall-clock time, optionally repeating weekly.
    static func scheduleFixed(id: UUID,
                              hour: Int,
                              minute: Int,
                              weekdays: Set<Int>,
                              label: String,
                              sound: String,
                              allowSnooze: Bool) async throws {
        let recurrence: Alarm.Schedule.Relative.Recurrence = weekdays.isEmpty
            ? .never
            : .weekly(weekdays.compactMap(Locale.Weekday.from(index:)))

        let schedule = Alarm.Schedule.relative(
            Alarm.Schedule.Relative(
                time: Alarm.Schedule.Relative.Time(hour: hour, minute: minute),
                repeats: recurrence
            )
        )

        let config = AlarmManager.AlarmConfiguration(
            countdownDuration: allowSnooze
                ? Alarm.CountdownDuration(preAlert: nil, postAlert: 9 * 60)
                : nil,
            schedule: schedule,
            attributes: attributes(title: label),
            stopIntent: ChimeStopIntent(alarmID: id),
            secondaryIntent: allowSnooze ? ChimeSnoozeIntent(alarmID: id) : nil,
            sound: .default
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
    }
}

extension Locale.Weekday {
    /// Calendar weekday index (1 = Sunday) -> Locale.Weekday
    static func from(index: Int) -> Locale.Weekday? {
        switch index {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}

/// Watches AlarmKit state and stops any alarm that has been alerting longer than
/// its configured auto-dismiss window. This is the behaviour Apple's Clock does
/// not give you, and it is the reason this app exists.
@MainActor
final class AutoDismissWatcher {
    static let shared = AutoDismissWatcher()
    private var task: Task<Void, Never>?
    private var alertingSince: [UUID: Date] = [:]
    private var stoppers: [UUID: Task<Void, Never>] = [:]

    func start(policyLookup: @escaping @Sendable (UUID) -> AutoDismiss?) {
        task?.cancel()
        task = Task { [weak self] in
            for await alarms in AlarmManager.shared.alarmUpdates {
                guard let self else { return }
                await self.handle(alarms, policyLookup: policyLookup)
            }
        }
    }

    private func handle(_ alarms: [Alarm],
                        policyLookup: @escaping @Sendable (UUID) -> AutoDismiss?) async {
        let alerting = Set(alarms.filter { $0.state == .alerting }.map(\.id))

        for id in alerting where alertingSince[id] == nil {
            alertingSince[id] = Date()
            guard let policy = policyLookup(id), policy.isEnabled else { continue }
            stoppers[id] = Task {
                try? await Task.sleep(for: .seconds(policy.seconds))
                guard !Task.isCancelled else { return }
                try? AlarmManager.shared.stop(id: id)
            }
        }

        for id in alertingSince.keys where !alerting.contains(id) {
            alertingSince[id] = nil
            stoppers[id]?.cancel()
            stoppers[id] = nil
        }
    }
}
#endif
