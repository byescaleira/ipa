import SwiftUI

public struct Avatar: View {
    public enum Content {
        case monogram(String)
        case symbol(String)
        case image(Image)
    }

    private let content: Content
    private let color: Color
    private let size: CGFloat

    public init(_ content: Content, color: Color, size: CGFloat = .badgeL) {
        self.content = content
        self.color = color
        self.size = size
    }

    public var body: some View {
        glyph
            .frame(width: size, height: size)
            .background(background, in: .circle)
            .clipShape(.circle)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder private var glyph: some View {
        switch content {
        case .monogram(let text):
            Text(verbatim: text)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, size * 0.12)
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(.white)
        case .image(let image):
            image
                .resizable()
                .scaledToFill()
        }
    }

    private var background: AnyShapeStyle {
        if case .image = content { return AnyShapeStyle(.subtleFill) }
        return AnyShapeStyle(color.gradient)
    }
}
