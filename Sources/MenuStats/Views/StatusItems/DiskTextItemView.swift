import SwiftUI

struct DiskTextItemView: View {
    let metrics: DiskMetrics
    let threshold: ThresholdConfig

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "DSK")

            Spacer(minLength: 2)

            Text(String(format: "%.0f%%", metrics.usagePercentage))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(threshold.color(for: metrics.usagePercentage)))
                .fixedSize()
        }
        .frame(height: 18)
        .fixedSize(horizontal: true, vertical: false)
    }
}
