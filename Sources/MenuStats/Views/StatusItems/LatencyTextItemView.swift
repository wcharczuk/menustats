import SwiftUI

struct LatencyTextItemView: View {
    let metrics: LatencyMetrics
    let threshold: ThresholdConfig

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "LAT")

            Spacer(minLength: 2)

            Text(metrics.formattedLatency)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(threshold.color(for: metrics.latencyMs ?? 0)))
                .fixedSize()
        }
        .frame(height: 18)
        .fixedSize(horizontal: true, vertical: false)
    }
}
