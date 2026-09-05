import SwiftUI

struct TimersView: View {
    @EnvironmentObject var engine: AlarmEngine
    @State private var duration: TimeInterval = 300
    @State private var autoDismiss: AutoDismiss = ChimeStore().defaultAutoDismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Duration", selection: $duration) {
                    ForEach(CrownDurations.values, id: \.self) {
                        Text(CrownDurations.label(for: $0)).tag($0)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Stop ringing after", selection: $autoDismiss) {
                    ForEach(AutoDismiss.presets, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu)

                Button("Start") {
                    Task { await engine.startTimer(duration: duration, autoDismiss: autoDismiss) }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                List(engine.timers) { t in
                    HStack {
                        Text(CrownDurations.label(for: t.duration))
                        Spacer()
                        Button("Cancel") { Task { await engine.cancelTimer(t.id) } }
                            .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .navigationTitle("Timers")
        }
    }
}
