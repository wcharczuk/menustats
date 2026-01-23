import SwiftUI

struct UTCClockStatusItemView: View {
    let timeString: String

    var body: some View {
        HStack(spacing: 1) {
            VerticalLabel(text: "UTC")

            Spacer(minLength: 2)

            Text(timeString)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .fixedSize()
        }
        .frame(height: 18)
        .fixedSize(horizontal: true, vertical: false)
    }
}
