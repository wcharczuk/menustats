import SwiftUI

struct ColorThresholds {
    static let normal = Color.primary
    static let warning = Color.blue
    static let critical = Color.purple

    static func color(for value: Double, threshold: ThresholdConfig) -> Color {
        if value <= threshold.greenMax {
            return normal
        } else if value <= threshold.yellowMax {
            return warning
        } else {
            return critical
        }
    }

    static func graphColor(for value: Double, threshold: ThresholdConfig) -> Color {
        if value <= threshold.greenMax {
            return normal
        } else if value <= threshold.yellowMax {
            return warning
        } else {
            return critical
        }
    }
}
