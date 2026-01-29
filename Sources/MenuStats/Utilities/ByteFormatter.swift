import Foundation

enum ByteUnit: String, CaseIterable {
    case bytes = "B"
    case kibibytes = "KiB"
    case mebibytes = "MiB"
    case gibibytes = "GiB"

    var divisor: Double {
        switch self {
        case .bytes: return 1
        case .kibibytes: return 1024
        case .mebibytes: return 1024 * 1024
        case .gibibytes: return 1024 * 1024 * 1024
        }
    }
}

struct ByteFormatter {
    static func format(_ bytes: UInt64, unit: ByteUnit? = nil) -> String {
        let value = Double(bytes)

        if let unit = unit {
            let converted = value / unit.divisor
            return formatValue(converted, unit: unit)
        }

        // Auto-select best unit
        let selectedUnit: ByteUnit
        if value >= ByteUnit.gibibytes.divisor {
            selectedUnit = .gibibytes
        } else if value >= ByteUnit.mebibytes.divisor {
            selectedUnit = .mebibytes
        } else if value >= ByteUnit.kibibytes.divisor {
            selectedUnit = .kibibytes
        } else {
            selectedUnit = .bytes
        }

        let converted = value / selectedUnit.divisor
        return formatValue(converted, unit: selectedUnit)
    }

    static func formatRate(_ bytesPerSecond: UInt64, unit: ByteUnit? = nil) -> String {
        let formatted = format(bytesPerSecond, unit: unit)
        return "\(formatted)/s"
    }

    private static func formatValue(_ value: Double, unit: ByteUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value < 10 ? 2 : (value < 100 ? 1 : 0)
        formatter.minimumFractionDigits = 0

        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
        return "\(formattedNumber) \(unit.rawValue)"
    }

    static func formatCompact(_ bytes: UInt64) -> String {
        let value = Double(bytes)

        if value >= ByteUnit.gibibytes.divisor {
            let gib = value / ByteUnit.gibibytes.divisor
            if gib >= 100 {
                return String(format: "%.0f GiB", gib)
            } else if gib >= 10 {
                return String(format: "%.1f GiB", gib)
            } else {
                return String(format: "%.2f GiB", gib)
            }
        } else if value >= ByteUnit.mebibytes.divisor {
            let mib = value / ByteUnit.mebibytes.divisor
            if mib >= 100 {
                return String(format: "%.0f MiB", mib)
            } else if mib >= 10 {
                return String(format: "%.1f MiB", mib)
            } else {
                return String(format: "%.2f MiB", mib)
            }
        } else if value >= ByteUnit.kibibytes.divisor {
            let kib = value / ByteUnit.kibibytes.divisor
            if kib >= 100 {
                return String(format: "%.0f KiB", kib)
            } else if kib >= 10 {
                return String(format: "%.1f KiB", kib)
            } else {
                return String(format: "%.2f KiB", kib)
            }
        } else {
            return String(format: "%.0f B", value)
        }
    }
}
