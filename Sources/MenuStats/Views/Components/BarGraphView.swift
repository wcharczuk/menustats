import SwiftUI

struct BarGraphView: View {
    let value: Double
    let threshold: ThresholdConfig
    let maxValue: Double

    var body: some View {
        GeometryReader { geometry in
            let normalizedValue = min(value / maxValue, 1.0)
            let fillHeight = geometry.size.height * normalizedValue
            let color = ColorThresholds.graphColor(for: value, threshold: threshold)

            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))

                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(height: fillHeight)
            }
        }
    }
}
