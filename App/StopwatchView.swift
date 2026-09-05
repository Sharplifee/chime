import SwiftUI

struct StopwatchView: View {
    @State private var elapsed: TimeInterval = 0
    @State private var running = false
    @State private var laps: [TimeInterval] = []
    @State private var start: Date?

    private let tick = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(format(elapsed))
                    .font(.system(size: 60, weight: .thin, design: .rounded))
                    .monospacedDigit()

                HStack(spacing: 40) {
                    Button(running ? "Lap" : "Reset") {
                        if running { laps.insert(elapsed, at: 0) }
                        else { elapsed = 0; laps = [] }
                    }
                    .buttonStyle(.bordered)

                    Button(running ? "Stop" : "Start") {
                        running.toggle()
                        start = running ? Date().addingTimeInterval(-elapsed) : nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(running ? .red : .green)
                }

                List(Array(laps.enumerated()), id: \.offset) { i, lap in
                    HStack {
                        Text("Lap \(laps.count - i)")
                        Spacer()
                        Text(format(lap)).monospacedDigit()
                    }
                }
            }
            .padding()
            .navigationTitle("Stopwatch")
            .onReceive(tick) { _ in
                if running, let s = start { elapsed = Date().timeIntervalSince(s) }
            }
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let cs = Int((t - floor(t)) * 100)
        return String(format: "%02d:%02d.%02d", m, s, cs)
    }
}
