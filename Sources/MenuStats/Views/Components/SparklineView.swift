import SwiftUI

struct SparklineView: View {
    let values: [Double]
    let threshold: ThresholdConfig
    let maxValue: Double?

    var body: some View {
        GeometryReader { geometry in
            let effectiveMax = maxValue ?? (values.max() ?? 1)
            let normalizedMax = max(effectiveMax, 1)

            Canvas { context, size in
                guard values.count > 1 else { return }

                let stepX = size.width / CGFloat(values.count - 1)
                let height = size.height

                var path = Path()

                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = min(value / normalizedMax, 1.0)
                    let y = height - (normalizedValue * height)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                // Determine color from latest value
                let currentValue = values.last ?? 0
                let color = ColorThresholds.graphColor(for: currentValue, threshold: threshold)

                context.stroke(path, with: .color(color), lineWidth: 1.5)

                // Fill under the line
                var fillPath = path
                fillPath.addLine(to: CGPoint(x: size.width, y: height))
                fillPath.addLine(to: CGPoint(x: 0, y: height))
                fillPath.closeSubpath()

                context.fill(fillPath, with: .color(color.opacity(0.3)))
            }
        }
    }
}
