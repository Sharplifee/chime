import SwiftUI

struct StopwatchView: View {
    @State private var elapsed: TimeInterval = 0
    @State private var running = false
    @State private var laps: [TimeInterval] = []
    @State private var start: Date?

    /// Preset start value. The stopwatch counts up from here instead of zero.
    @State private var offset: TimeInterval = 0
    @State private var showPreset = false
    @State private var pHours = 0
    @State private var pMinutes = 0
    @State private var pSeconds = 0

    private let tick = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    private var hasStarted: Bool { running || elapsed > offset }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(format(elapsed))
                    .font(.system(size: 60, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                if offset > 0 {
                    Text("started from \(format(offset))")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                // Same rotary wheels the timer uses, applied to the start value.
                if showPreset {
                    HStack(spacing: 0) {
                        wheel(value: $pHours, range: 0..<24, unit: "hours")
                        wheel(value: $pMinutes, range: 0..<60, unit: "min")
                        wheel(value: $pSeconds, range: 0..<60, unit: "sec")
                    }
                    .frame(height: 160)

                    Button("Set start time") { applyPreset() }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                } else if !hasStarted {
                    Button {
                        showPreset = true
                    } label: {
                        Label(offset > 0 ? "Change start time" : "Start from a preset time",
                              systemImage: "dial.medium")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                HStack(spacing: 40) {
                    Button(running ? "Lap" : "Reset") {
                        if running {
                            laps.insert(elapsed, at: 0)
                        } else {
                            elapsed = offset
                            laps = []
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(running ? "Stop" : "Start") {
                        running.toggle()
                        if running {
                            showPreset = false
                            start = Date().addingTimeInterval(-elapsed)
                        } else {
                            start = nil
                        }
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
            .onAppear {
                if elapsed == 0 { elapsed = offset }
            }
        }
    }

    @ViewBuilder
    private func wheel(value: Binding<Int>, range: Range<Int>, unit: String) -> some View {
        HStack(spacing: 2) {
            Picker("", selection: value) {
                ForEach(range, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(width: 62)
            .clipped()
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func applyPreset() {
        offset = TimeInterval(pHours * 3600 + pMinutes * 60 + pSeconds)
        elapsed = offset
        laps = []
        showPreset = false
    }

    private func format(_ t: TimeInterval) -> String {
        let total = Int(t)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        let cs = Int((t - floor(t)) * 100)
        if h > 0 { return String(format: "%d:%02d:%02d.%02d", h, m, s, cs) }
        return String(format: "%02d:%02d.%02d", m, s, cs)
    }
}
