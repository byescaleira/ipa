import IPADesignSystem
import IPADomain
import SwiftUI

public struct AccountAvatar: View {
    private let account: Account?
    private let size: CGFloat

    public init(_ account: Account?, size: CGFloat = .badgeL) {
        self.account = account
        self.size = size
    }

    public var body: some View {
        Avatar(account.avatarContent, color: account.avatarColor.color, size: size)
            .accessibilityLabel(account.avatarAccessibilityLabel)
    }

    @MainActor public static func image(for account: Account, size: CGFloat, scale: CGFloat)
        -> Image
    {
        let renderer = ImageRenderer(content: AccountAvatar(account, size: size))
        renderer.scale = scale
        guard let image = renderer.cgImage else { return Image(systemName: "person.crop.circle") }
        return Image(decorative: image, scale: scale)
    }
}
