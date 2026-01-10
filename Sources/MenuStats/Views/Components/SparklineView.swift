import SwiftUI

struct SparklineView: View {
    let values: [Double]
    let threshold: ThresholdConfig
    let maxValue: Double?
    var overrideColor: Color?
    var thresholdValue: Double? // Optional value to use for threshold color calculation (e.g., percentage)

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

                // Determine color from override or threshold
                let color: Color
                if let overrideColor = overrideColor {
                    color = overrideColor
                } else {
                    // Use thresholdValue if provided, otherwise fall back to last value
                    let colorValue = thresholdValue ?? values.last ?? 0
                    color = ColorThresholds.graphColor(for: colorValue, threshold: threshold)
                }

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
