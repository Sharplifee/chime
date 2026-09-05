import SwiftUI

/// The screen the complication opens straight into: scroll the Digital Crown to a
/// duration, tap once, timer starts. No navigation, no keyboard, no app browsing.
struct CrownTimerView: View {
    @State private var index: Double = 4          // default 5 min
    @State private var started = false
    @Environment(\.dismiss) private var dismiss

    private var values: [TimeInterval] { CrownDurations.values }

    private var selected: TimeInterval {
        let i = min(max(Int(index.rounded()), 0), values.count - 1)
        return values[i]
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(CrownDurations.label(for: selected))
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: selected)

            Text("stops after \(ChimeStore().defaultAutoDismiss.label)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button {
                start()
            } label: {
                Text(started ? "Started" : "Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(started)
        }
        .padding(.horizontal)
        .focusable()
        .digitalCrownRotation($index,
                              from: 0,
                              through: Double(values.count - 1),
                              by: 1,
                              sensitivity: .medium,
                              isContinuous: false,
                              isHapticFeedbackEnabled: true)
    }

    private func start() {
        started = true
        ChimeConnectivity.shared.startTimer(
            duration: selected,
            autoDismiss: ChimeStore().defaultAutoDismiss.seconds
        )
        Task {
            try? await Task.sleep(for: .seconds(1))
            dismiss()
        }
    }
}
