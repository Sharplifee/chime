import SwiftUI

struct WatchAlarmListView: View {
    @State private var alarms: [ChimeAlarm] = ChimeStore().loadAlarms()

    var body: some View {
        List {
            if alarms.isEmpty {
                Text("No alarms")
                    .foregroundStyle(.secondary)
            }
            ForEach(alarms) { alarm in
                HStack {
                    VStack(alignment: .leading) {
                        Text(String(format: "%d:%02d", alarm.hour, alarm.minute))
                            .font(.title3.monospacedDigit())
                        Text(alarm.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: alarm.isEnabled ? "bell.fill" : "bell.slash")
                        .foregroundStyle(alarm.isEnabled ? .orange : .secondary)
                }
            }
        }
        .navigationTitle("Alarms")
    }
}
