import SwiftUI

struct DiskStatusItemView: View {
    let metrics: DiskMetrics
    let threshold: ThresholdConfig

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "DSK")

            BarGraphView(
                value: metrics.usagePercentage,
                threshold: threshold,
                maxValue: 100
            )
            .frame(width: 8, height: 16)
        }
        .frame(height: 18)
    }
}
