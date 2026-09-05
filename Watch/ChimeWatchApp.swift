import SwiftUI

@main
struct ChimeWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
}

struct WatchRootView: View {
    var body: some View {
        TabView {
            CrownTimerView()
            WatchAlarmListView()
        }
        .tabViewStyle(.verticalPage)
    }
}
