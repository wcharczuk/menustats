import SwiftUI

struct MemoryStatusItemView: View {
    let metrics: MemoryMetrics
    let threshold: ThresholdConfig

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "MEM")

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
