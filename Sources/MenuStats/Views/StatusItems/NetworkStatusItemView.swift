import SwiftUI

struct NetworkStatusItemView: View {
    let metrics: NetworkMetrics
    let threshold: ThresholdConfig

    private var sendHistoryDouble: [Double] {
        metrics.sendHistory.map { Double($0) }
    }

    private var receiveHistoryDouble: [Double] {
        metrics.receiveHistory.map { Double($0) }
    }

    private var maxNetworkValue: Double {
        // Use link speed as max so graph shows absolute bandwidth utilization
        let linkSpeed = Double(metrics.linkSpeedBytesPerSecond)
        guard linkSpeed > 0 else {
            // Fallback to history max if link speed unavailable
            let maxSend = metrics.sendHistory.max() ?? 0
            let maxReceive = metrics.receiveHistory.max() ?? 0
            return Double(max(maxSend, maxReceive, 1))
        }
        return linkSpeed
    }

    var body: some View {
        HStack(spacing: 2) {
            VerticalLabel(text: "NET")

            VStack(spacing: 2) {
                HStack(spacing: 1) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 5))
                        .foregroundStyle(.primary)
                    SparklineView(
                        values: sendHistoryDouble,
                        threshold: threshold,
                        maxValue: maxNetworkValue,
                        thresholdValue: metrics.sendPercentage
                    )
                    .frame(width: 28, height: 8)
                }

                HStack(spacing: 1) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 5))
                        .foregroundStyle(.primary)
                    SparklineView(
                        values: receiveHistoryDouble,
                        threshold: threshold,
                        maxValue: maxNetworkValue,
                        thresholdValue: metrics.receivePercentage
                    )
                    .frame(width: 28, height: 8)
                }
            }
        }
        .frame(height: 18)
    }
}
