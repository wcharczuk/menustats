import SwiftUI

struct CPUTextItemView: View {
    let metrics: CPUMetrics
    let threshold: ThresholdConfig

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "CPU")

            Spacer(minLength: 2)

            Text(String(format: "%.0f%%", metrics.totalUsage))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(threshold.color(for: metrics.totalUsage)))
                .fixedSize()
        }
        .frame(height: 18)
        .fixedSize(horizontal: true, vertical: false)
    }
}
