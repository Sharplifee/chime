import WidgetKit
import SwiftUI
#if canImport(AlarmKit)
import AlarmKit

/// AlarmKit renders its countdown and alerting UI through a Live Activity that
/// must live in a widget extension. Without this the alarm has nowhere to draw
/// on the Lock Screen or in the Dynamic Island.
struct ChymeAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<ChymeMetadata>.self) { context in
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
                Text(context.attributes.presentation.alert.title)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.6))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.fill")
                        .foregroundStyle(context.attributes.tintColor)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.presentation.alert.title)
                        .font(.headline)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
            } compactTrailing: {
                Image(systemName: "timer")
            } minimal: {
                Image(systemName: "alarm.fill")
            }
            .keylineTint(context.attributes.tintColor)
        }
    }
}

@main
struct ChymeWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChymeAlarmLiveActivity()
    }
}
#endif
