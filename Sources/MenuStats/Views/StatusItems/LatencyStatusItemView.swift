import SwiftUI

struct LatencyStatusItemView: View {
    let metrics: LatencyMetrics
    let threshold: ThresholdConfig

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "LAT")

            SparklineView(
                values: metrics.history,
                threshold: threshold,
                maxValue: metrics.sparklineMaxValue,
                thresholdValue: metrics.latencyMs
            )
            .frame(width: 28, height: 16)
        }
        .frame(height: 18)
    }
}
