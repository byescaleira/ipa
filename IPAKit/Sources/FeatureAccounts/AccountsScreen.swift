import FeatureCore
import IPADesignSystem
import IPADomain
import SwiftUI

public struct AccountsScreen: View {
    @Environment(AccountsModel.self) private var accounts
    @Environment(SessionModel.self) private var session
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    public init() {}

    public var body: some View {
        @Bindable var accounts = accounts
        AdaptiveList {
            ActiveAccountSection()
            OtherAccountsSection()
            EngineSection()
            RemoveAccountSection()
        }
        .accountsEmptyState(when: accounts.isEmpty)
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Account", systemImage: "person.badge.plus") {
                    open(.signIn, in: section)
                }
                .tint(Color.primary)
            }
        }
        .confirmationDialog(
            accounts.removalTitle, isPresented: $accounts.isConfirmingRemoval,
            titleVisibility: .visible, presenting: accounts.removal
        ) { _ in
            Button("Remove", role: .destructive) { accounts.confirmRemoval() }
        } message: { _ in
            Text(verbatim: accounts.removalMessage)
        }
        .errorAlert($accounts.error)
        .refreshable { await reload() }
        .task(id: session.generation) { await reload() }
        .navigationTitle("Accounts")
    }

    private func reload() async {
        accounts.load()
        await session.refreshAvailability()
    }
}

private struct ActiveAccountSection: View {
    @Environment(AccountsModel.self) private var accounts
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let active = accounts.active {
            Section {
            } header: {
                VStack(spacing: .spaceS) {
                    AccountAvatar(active, size: .medallion)
                        .shadow(color: .black.opacity(.opacityFill), radius: .spaceM, y: .spaceS)
                        .padding(.bottom, .spaceXS)
                    Text(verbatim: active.displayName)
                        .font(.titleLarge)
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(verbatim: active.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Chip(active.storefront.title, color: appTint, shape: .capsule)
                }
                .id(active.email)
                .transition(.opacity)
                .textCase(nil)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spaceL)
                .accessibilityElement(children: .combine)
                .animation(reduceMotion ? nil : .smooth, value: active.email)
            }
        }
    }
}

private struct OtherAccountsSection: View {
    @Environment(AccountsModel.self) private var accounts
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !accounts.others.isEmpty {
            Section {
                ForEach(accounts.others) { account in
                    Button {
                        withAnimation(reduceMotion ? nil : .smooth) { accounts.select(account) }
                    } label: {
                        AccountRow(account: account)
                    }
                    .tint(Color.primary)
                    .swipeActions {
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            accounts.removal = account
                        }
                    }
                    .contextMenu {
                        Button("Use This Account", systemImage: "checkmark.circle") {
                            accounts.select(account)
                        }
                        Divider()
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            accounts.removal = account
                        }
                    }
                }
            } header: {
                Text("Other Accounts").sectionTitle()
            } footer: {
                Text(verbatim: accounts.othersFooter)
            }
            .sensoryFeedback(.selection, trigger: accounts.activeEmail)
        }
    }
}

private struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: .spaceM) {
            AccountAvatar(account, size: .badgeL)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(verbatim: account.displayName).font(.rowTitle).lineLimit(1)
                Text(verbatim: account.email)
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: account.storefront.flag)
                .accessibilityLabel(account.storefront.name)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct EngineSection: View {
    @Environment(SessionModel.self) private var session

    var body: some View {
        Section {
            EngineStatusRows(session.availability)
        } header: {
            Text("Store Engine").sectionTitle()
        } footer: {
            Text("Search works without the engine. Signing in, versions and downloads need it.")
        }
    }
}

private struct RemoveAccountSection: View {
    @Environment(AccountsModel.self) private var accounts

    var body: some View {
        if let active = accounts.active {
            Section {
                Button("Remove This Account", role: .destructive) {
                    accounts.removal = active
                }
                .font(.buttonLabel)
                .frame(maxWidth: .infinity)
            } footer: {
                Text(verbatim: accounts.removeFooter)
            }
        }
    }
}

private struct AccountsEmptyState: View {
    @Environment(AccountsModel.self) private var accounts
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        EmptyStateView(
            title: "No accounts yet",
            description:
                "Sign in with an Apple ID to list versions and download free apps. The password stays in this device's Keychain.",
            actionTitle: "Add Account"
        ) {
            open(.signIn, in: section)
        } example: {
            ForEach(accounts.examples) { account in
                HStack(spacing: .spaceM) {
                    AccountAvatar(account, size: .badgeM)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: account.displayName).font(.subheadline.weight(.semibold))
                        Text(verbatim: account.email).font(.caption).foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    Spacer(minLength: .spaceS)
                    Text(verbatim: account.storefront.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
            }
        }
    }
}

extension View {
    @ViewBuilder fileprivate func accountsEmptyState(when isEmpty: Bool) -> some View {
        if isEmpty {
            AccountsEmptyState()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.groupedBackground)
        } else {
            self
        }
    }
}
