import SwiftUI

struct NetworkTextItemView: View {
    let metrics: NetworkMetrics

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "NET")

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 6))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 2)
                    Text(ByteFormatter.formatCompact(metrics.bytesSentPerSecond))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 0) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 6))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 2)
                    Text(ByteFormatter.formatCompact(metrics.bytesReceivedPerSecond))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(height: 18)
    }
}
