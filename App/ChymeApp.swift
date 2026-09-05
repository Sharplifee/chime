import SwiftUI

@main
struct ChymeApp: App {
    @StateObject private var engine = AlarmEngine.shared

    init() {
        _ = ChymeConnectivity.shared
        #if canImport(AlarmKit)
        Task { @MainActor in
            AutoDismissWatcher.shared.start { id in
                let store = ChymeStore()
                if let a = store.loadAlarms().first(where: { $0.id == id }) { return a.autoDismiss }
                if let t = store.loadTimers().first(where: { $0.id == id }) { return t.autoDismiss }
                return store.defaultAutoDismiss
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabView().environmentObject(engine)
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            AlarmsView().tabItem { Label("Alarms", systemImage: "alarm") }
            TimersView().tabItem { Label("Timers", systemImage: "timer") }
            StopwatchView().tabItem { Label("Stopwatch", systemImage: "stopwatch") }
        }
        .tint(.orange)
    }
}
