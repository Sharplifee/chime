import WidgetKit
import SwiftUI
import AppIntents

/// Complication set. Written once, offered by the system to every watch face
/// that exposes a third-party slot of the matching shape.
struct ChymeTimerEntry: TimelineEntry {
    let date: Date
    let defaultDuration: TimeInterval
}

struct ChymeTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChymeTimerEntry {
        ChymeTimerEntry(date: .now, defaultDuration: 300)
    }
    func getSnapshot(in context: Context, completion: @escaping (ChymeTimerEntry) -> Void) {
        completion(ChymeTimerEntry(date: .now,
                                   defaultDuration: ChymeStore().defaultComplicationDuration))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ChymeTimerEntry>) -> Void) {
        let e = ChymeTimerEntry(date: .now,
                                defaultDuration: ChymeStore().defaultComplicationDuration)
        completion(Timeline(entries: [e], policy: .never))
    }
}

struct ChymeTimerComplicationView: View {
    @Environment(\.widgetFamily) var family
    var entry: ChymeTimerEntry

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
            Label("Chyme \(CrownDurations.label(for: entry.defaultDuration))",
                  systemImage: "timer")
        case .accessoryRectangular:
            HStack {
                Image(systemName: "timer")
                VStack(alignment: .leading) {
                    Text("Chyme").font(.headline)
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

struct ChymeTimerComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ChymeTimerComplication",
                            provider: ChymeTimerProvider()) { entry in
            ChymeTimerComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Chyme Timer")
        .description("Tap to pick a duration and start a timer.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner,
                            .accessoryInline, .accessoryRectangular])
    }
}

@main
struct ChymeWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChymeTimerComplication()
    }
}
