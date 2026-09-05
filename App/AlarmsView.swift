import SwiftUI

struct AlarmsView: View {
    @EnvironmentObject var engine: AlarmEngine
    @State private var editing: ChymeAlarm?

    var body: some View {
        NavigationStack {
            List {
                ForEach(engine.alarms) { alarm in
                    AlarmRow(alarm: alarm)
                        .contentShape(Rectangle())
                        .onTapGesture { editing = alarm }
                }
                .onDelete { idx in
                    let ids = idx.map { engine.alarms[$0].id }
                    Task { for id in ids { await engine.delete(alarmID: id) } }
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                Button {
                    editing = ChymeAlarm(minuteOfDay: 7 * 60)
                } label: { Image(systemName: "plus") }
            }
            .sheet(item: $editing) { AlarmEditor(alarm: $0) }
        }
    }
}

struct AlarmRow: View {
    @EnvironmentObject var engine: AlarmEngine
    let alarm: ChymeAlarm

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%d:%02d", alarm.hour, alarm.minute))
                    .font(.system(size: 40, weight: .light, design: .rounded))
                    .monospacedDigit()
                Text("\(alarm.label) · stops after \(alarm.autoDismiss.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { v in Task { await engine.setEnabled(v, alarmID: alarm.id) } }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct AlarmEditor: View {
    @EnvironmentObject var engine: AlarmEngine
    @Environment(\.dismiss) private var dismiss
    @State var alarm: ChymeAlarm

    init(alarm: ChymeAlarm) { _alarm = State(initialValue: alarm) }

    private var time: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: alarm.hour,
                                      minute: alarm.minute,
                                      second: 0, of: Date()) ?? Date()
            },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                alarm.minuteOfDay = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)

                TextField("Label", text: $alarm.label)

                Toggle("Snooze", isOn: $alarm.snoozeEnabled)

                Section("Stop ringing after") {
                    Picker("Auto-dismiss", selection: $alarm.autoDismiss) {
                        ForEach(AutoDismiss.presets, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Alarm")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await engine.upsert(alarm); dismiss() }
                    }
                }
            }
        }
    }
}
