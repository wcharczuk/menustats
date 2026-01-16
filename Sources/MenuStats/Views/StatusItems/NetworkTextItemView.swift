import SwiftUI

struct NetworkTextItemView: View {
    let metrics: NetworkMetrics

    // Fixed width to accommodate 6 digits + unit (e.g., "999.99 GiB")
    private let measureWidth: CGFloat = 64

    // Threshold for MiB (1024 * 1024)
    private let mibThreshold: UInt64 = 1_048_576

    private func fontWeight(for bytes: UInt64) -> Font.Weight {
        bytes >= mibThreshold ? .bold : .light
    }

    var body: some View {
        HStack(spacing: 2) {
            VerticalLabel(text: "NET")

            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 6))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 2)
                    Text(ByteFormatter.formatCompact(metrics.bytesSentPerSecond))
                        .font(.system(size: 8, weight: fontWeight(for: metrics.bytesSentPerSecond), design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .frame(width: measureWidth)

                HStack(spacing: 0) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 6))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 2)
                    Text(ByteFormatter.formatCompact(metrics.bytesReceivedPerSecond))
                        .font(.system(size: 8, weight: fontWeight(for: metrics.bytesReceivedPerSecond), design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .frame(width: measureWidth)
            }
        }
        .frame(height: 18)
    }
}
