import IPADesignSystem
import IPADomain
import SwiftUI

public struct AccountMenu: View {
    @Environment(AccountsModel.self) private var accounts
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    @Environment(\.displayScale) private var displayScale

    public init() {}

    public var body: some View {
        @Bindable var accounts = accounts
        Menu {
            if !accounts.accounts.isEmpty {
                Picker(selection: $accounts.selection) {
                    ForEach(accounts.accounts) { account in
                        Label {
                            Text(verbatim: account.displayName)
                        } icon: {
                            AccountAvatar.image(for: account, size: .badgeS, scale: displayScale)
                                .renderingMode(.original)
                        }
                        .tag(Optional(account.email))
                    }
                } label: {
                    EmptyView()
                }
                Divider()
            }
            Button("Add Account", systemImage: "person.badge.plus") {
                open(.signIn, in: section)
            }
        } label: {
            AccountAvatar(accounts.active, size: .badgeM)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("Account")
    }
}
