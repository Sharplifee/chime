import Foundation

/// Shared persistence via App Group so the widget/complication extension and the
/// app read the same alarms and timers.
public struct ChimeStore {
    public static let appGroup = "group.com.connor.chime"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroup) ?? .standard
    }

    public init() {}

    public func loadAlarms() -> [ChimeAlarm] { decode("alarms") }
    public func loadTimers() -> [ChimeTimer] { decode("timers") }

    public func save(alarms: [ChimeAlarm]) { encode(alarms, "alarms") }
    public func save(timers: [ChimeTimer]) { encode(timers, "timers") }

    /// Duration the watch complication starts by default on a single tap.
    public var defaultComplicationDuration: TimeInterval {
        get {
            let v = defaults.double(forKey: "defaultComplicationDuration")
            return v > 0 ? v : 300
        }
        nonmutating set { defaults.set(newValue, forKey: "defaultComplicationDuration") }
    }

    public var defaultAutoDismiss: AutoDismiss {
        get {
            let v = defaults.object(forKey: "defaultAutoDismiss") as? Int
            return AutoDismiss(seconds: v ?? 300)
        }
        nonmutating set { defaults.set(newValue.seconds, forKey: "defaultAutoDismiss") }
    }

    private func decode<T: Decodable>(_ key: String) -> [T] {
        guard let d = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([T].self, from: d)) ?? []
    }

    private func encode<T: Encodable>(_ v: [T], _ key: String) {
        guard let d = try? JSONEncoder().encode(v) else { return }
        defaults.set(d, forKey: key)
    }
}
