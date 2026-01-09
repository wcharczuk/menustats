import SwiftUI

struct HistoryGraphView: View {
    let values: [Double]
    let threshold: ThresholdConfig
    let maxValue: Double?
    let title: String
    let valueFormatter: (Double) -> String

    init(
        values: [Double],
        threshold: ThresholdConfig,
        maxValue: Double? = nil,
        title: String = "",
        valueFormatter: @escaping (Double) -> String = { String(format: "%.1f", $0) }
    ) {
        self.values = values
        self.threshold = threshold
        self.maxValue = maxValue
        self.title = title
        self.valueFormatter = valueFormatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let currentValue = values.last {
                        Text(valueFormatter(currentValue))
                            .font(.caption)
                            .foregroundStyle(ColorThresholds.graphColor(for: currentValue, threshold: threshold))
                    }
                }
            }

            GeometryReader { geometry in
                let effectiveMax = maxValue ?? (values.max() ?? 1)
                let normalizedMax = max(effectiveMax, 1)

                Canvas { context, size in
                    // Draw grid lines
                    let gridColor = Color.gray.opacity(0.2)
                    for i in 0..<5 {
                        let y = size.height * CGFloat(i) / 4
                        var gridPath = Path()
                        gridPath.move(to: CGPoint(x: 0, y: y))
                        gridPath.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(gridPath, with: .color(gridColor), lineWidth: 0.5)
                    }

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

                    let currentValue = values.last ?? 0
                    let color = ColorThresholds.graphColor(for: currentValue, threshold: threshold)

                    context.stroke(path, with: .color(color), lineWidth: 2)

                    // Fill
                    var fillPath = path
                    fillPath.addLine(to: CGPoint(x: size.width, y: height))
                    fillPath.addLine(to: CGPoint(x: 0, y: height))
                    fillPath.closeSubpath()

                    context.fill(fillPath, with: .color(color.opacity(0.2)))
                }
            }
            .background(Color.black.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
