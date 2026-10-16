import IPADesignSystem
import SwiftUI

public struct AppArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let url: URL?
    private let size: CGFloat

    public init(_ url: URL?, size: CGFloat = .badgeXL) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: reduceMotion ? nil : .smooth)) {
            phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "app.dashed")
                    .font(.icon(.m))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.subtleFill)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.2237, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
                .strokeBorder(.separator, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}
