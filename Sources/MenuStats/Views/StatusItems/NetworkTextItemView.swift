import SwiftUI

struct NetworkTextItemView: View {
    let metrics: NetworkMetrics

    var body: some View {
        HStack(spacing: 2) {
            VerticalLabel(text: "NET")

            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 6))
                        .foregroundStyle(.primary)
                        .padding(.trailing, 2)
                    Text(ByteFormatter.formatCompact(metrics.bytesSentPerSecond))
                        .font(.system(size: 8, weight: .light, design: .monospaced))
                        .foregroundStyle(.primary)
                        .fixedSize()
                }

                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 6))
                        .foregroundStyle(.primary)
                        .padding(.trailing, 2)
                    Text(ByteFormatter.formatCompact(metrics.bytesReceivedPerSecond))
                        .font(.system(size: 8, weight: .light, design: .monospaced))
                        .foregroundStyle(.primary)
                        .fixedSize()
                }
            }
        }
        .frame(height: 18)
        .fixedSize(horizontal: true, vertical: false)
    }
}
