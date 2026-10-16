import FeatureCore
import IPADesignSystem
import IPADomain
import SwiftUI

public struct StorefrontScreen: View {
    @Environment(StorePreferences.self) private var preferences
    @Environment(AccountsModel.self) private var accounts

    public init() {}

    public var body: some View {
        ModelHost(StorefrontModel(preferences: preferences, accounts: accounts)) {
            StorefrontList()
        }
    }
}

private struct StorefrontList: View {
    @Environment(StorefrontModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List {
            AccountStoreSection()
            StorefrontsSection()
        }
        .overlay {
            if model.isShowingNoResults { ContentUnavailableView.search(text: model.query) }
        }
        .fontDesign(.rounded)
        .readableWidth()
        .searchable(text: $model.text, prompt: Text("Country or region"))
        .autocorrectionDisabled()
        .sensoryFeedback(.selection, trigger: model.selection)
        .navigationTitle("Storefront")
    }
}

private struct AccountStoreSection: View {
    @Environment(StorefrontModel.self) private var model
    @Environment(\.close) private var close

    var body: some View {
        if model.isShowingAccountStore {
            Section {
                Button {
                    model.select(nil)
                    close()
                } label: {
                    HStack(spacing: .spaceM) {
                        VStack(alignment: .leading, spacing: .spaceHairline) {
                            Text("Account's Store").font(.rowTitle)
                            Text(verbatim: model.accountStoreDetail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        SelectionMark(isSelected: model.isAccountStoreSelected)
                    }
                    .contentShape(.rect)
                }
                .tint(Color.primary)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(model.isAccountStoreSelected ? .isSelected : [])
            } footer: {
                Text("Results, prices and versions come from the store you pick.")
            }
        }
    }
}

private struct StorefrontsSection: View {
    @Environment(StorefrontModel.self) private var model

    var body: some View {
        if !model.storefronts.isEmpty {
            Section {
                ForEach(model.storefronts) { StorefrontRow(storefront: $0) }
            } header: {
                Text("All Stores").sectionTitle()
            }
        }
    }
}

private struct StorefrontRow: View {
    @Environment(StorefrontModel.self) private var model
    @Environment(\.close) private var close
    let storefront: Storefront

    var body: some View {
        let isSelected = model.isSelected(storefront)
        Button {
            model.select(storefront)
            close()
        } label: {
            HStack(spacing: .spaceM) {
                Text(verbatim: storefront.flag).font(.title3).accessibilityHidden(true)
                Text(verbatim: storefront.name).frame(maxWidth: .infinity, alignment: .leading)
                SelectionMark(isSelected: isSelected)
            }
            .contentShape(.rect)
        }
        .tint(Color.primary)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
