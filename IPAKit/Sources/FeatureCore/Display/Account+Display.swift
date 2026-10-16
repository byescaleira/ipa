import IPADesignSystem
import IPADomain

extension Account {
    public var avatarColor: RetroColor {
        let palette: [RetroColor] = [.burntOrange, .denim, .olive, .mustard, .teal, .plum, .rust]
        let seed = email.lowercased().unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[seed % palette.count]
    }
}

extension Optional where Wrapped == Account {
    public var avatarContent: Avatar.Content {
        guard let initials = self?.initials, !initials.isEmpty else {
            return .symbol("person.fill")
        }
        return .monogram(initials)
    }

    public var avatarColor: RetroColor { self?.avatarColor ?? .default }

    public var avatarAccessibilityLabel: String {
        guard let initials = self?.initials, !initials.isEmpty else {
            return String(appLocalized: "Account photo")
        }
        return String(appLocalized: "Account photo with the initials \(initials)")
    }
}
