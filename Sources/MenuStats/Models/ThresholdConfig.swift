import Foundation
import SwiftUI

struct ThresholdConfig: Codable, Equatable, Sendable {
    var greenMax: Double
    var yellowMax: Double

    func color(for value: Double) -> Color {
        if value <= greenMax {
            return .primary
        } else if value <= yellowMax {
            return .blue
        } else {
            return .purple
        }
    }

    func isCritical(_ value: Double) -> Bool {
        value > yellowMax
    }

    func isWarning(_ value: Double) -> Bool {
        value > greenMax && value <= yellowMax
    }
}
