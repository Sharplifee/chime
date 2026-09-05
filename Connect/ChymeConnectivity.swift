import Foundation
import WatchConnectivity

/// Watch taps the complication -> message goes to the phone -> phone schedules the
/// real AlarmKit alarm. The watch never schedules, because AlarmKit has no
/// watchOS target.
public final class ChymeConnectivity: NSObject, ObservableObject, WCSessionDelegate, @unchecked Sendable {
    public static let shared = ChymeConnectivity()

    public enum Action: String {
        case startTimer, stopTimer, toggleAlarm, sync
    }

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    public func startTimer(duration: TimeInterval, autoDismiss: Int) {
        send([
            "action": Action.startTimer.rawValue,
            "duration": duration,
            "autoDismiss": autoDismiss
        ])
    }

    private func send(_ payload: [String: Any]) {
        let s = WCSession.default
        guard s.activationState == .activated else { return }
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil, errorHandler: { _ in
                try? s.updateApplicationContext(payload)
            })
        } else {
            s.transferUserInfo(payload)
        }
    }

    // MARK: - WCSessionDelegate

    public func session(_ session: WCSession,
                        activationDidCompleteWith state: WCSessionActivationState,
                        error: Error?) {}

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handle(userInfo)
    }

    private func handle(_ payload: [String: Any]) {
        #if os(iOS)
        guard let raw = payload["action"] as? String,
              let action = Action(rawValue: raw) else { return }
        switch action {
        case .startTimer:
            let duration = payload["duration"] as? TimeInterval ?? 300
            let dismiss = payload["autoDismiss"] as? Int ?? 300
            Task { @MainActor in
                await AlarmEngine.shared.startTimer(duration: duration,
                                                    autoDismiss: AutoDismiss(seconds: dismiss))
            }
        default:
            break
        }
        #endif
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif
}
