import SwiftUI

struct CoreGridView: View {
    let coreUsages: [CPUCoreUsage]
    let threshold: ThresholdConfig

    private let columns = [
        GridItem(.adaptive(minimum: 40, maximum: 50), spacing: 4)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(coreUsages) { core in
                CoreCell(core: core, threshold: threshold)
            }
        }
    }
}

struct CoreCell: View {
    let core: CPUCoreUsage
    let threshold: ThresholdConfig

    var body: some View {
        VStack(spacing: 2) {
            // Core type indicator
            Text("\(core.coreType.rawValue)\(core.id)")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            // Usage bar
            GeometryReader { geometry in
                let normalizedValue = min(core.usage / 100, 1.0)
                let fillHeight = geometry.size.height * normalizedValue
                let color = ColorThresholds.graphColor(for: core.usage, threshold: threshold)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(height: fillHeight)
                }
            }
            .frame(height: 30)

            // Usage percentage
            Text(String(format: "%.0f%%", core.usage))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(ColorThresholds.graphColor(for: core.usage, threshold: threshold))
        }
        .frame(width: 40)
    }
}
