import SwiftUI

struct CPUStatusItemView: View {
    let metrics: CPUMetrics
    let threshold: ThresholdConfig

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "CPU")

            SparklineView(
                values: metrics.history,
                threshold: threshold,
                maxValue: 100
            )
            .frame(width: 28, height: 16)
        }
        .frame(height: 18)
    }
}
