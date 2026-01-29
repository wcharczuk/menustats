import SwiftUI

struct VerticalLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 7, weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
            .rotationEffect(.degrees(-90))
            .fixedSize()
            .frame(width: 10, height: 18)
    }
}
