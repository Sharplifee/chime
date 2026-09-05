import WidgetKit
import SwiftUI
import AppIntents

/// Complication set. Written once, offered by the system to every watch face
/// that exposes a third-party slot of the matching shape.
struct ChimeTimerEntry: TimelineEntry {
    let date: Date
    let defaultDuration: TimeInterval
}

struct ChimeTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChimeTimerEntry {
        ChimeTimerEntry(date: .now, defaultDuration: 300)
    }
    func getSnapshot(in context: Context, completion: @escaping (ChimeTimerEntry) -> Void) {
        completion(ChimeTimerEntry(date: .now,
                                   defaultDuration: ChimeStore().defaultComplicationDuration))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ChimeTimerEntry>) -> Void) {
        let e = ChimeTimerEntry(date: .now,
                                defaultDuration: ChimeStore().defaultComplicationDuration)
        completion(Timeline(entries: [e], policy: .never))
    }
}

struct ChimeTimerComplicationView: View {
    @Environment(\.widgetFamily) var family
    var entry: ChimeTimerEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "timer")
                    .font(.title3)
            }
        case .accessoryCorner:
            Image(systemName: "timer")
                .font(.title2)
                .widgetLabel {
                    Text(CrownDurations.label(for: entry.defaultDuration))
                }
        case .accessoryInline:
            Label("Chime \(CrownDurations.label(for: entry.defaultDuration))",
                  systemImage: "timer")
        case .accessoryRectangular:
            HStack {
                Image(systemName: "timer")
                VStack(alignment: .leading) {
                    Text("Chime").font(.headline)
                    Text("Tap to start \(CrownDurations.label(for: entry.defaultDuration))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        default:
            Image(systemName: "timer")
        }
    }
}

struct ChimeTimerComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ChimeTimerComplication",
                            provider: ChimeTimerProvider()) { entry in
            ChimeTimerComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Chime Timer")
        .description("Tap to pick a duration and start a timer.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner,
                            .accessoryInline, .accessoryRectangular])
    }
}

@main
struct ChimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChimeTimerComplication()
    }
}
