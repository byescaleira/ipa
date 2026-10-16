import FeatureCore
import IPADesignSystem
import SwiftUI

public struct AccountsScreen: View {
    @Environment(AccountsModel.self) private var accounts
    @Environment(SessionModel.self) private var session

    public init() {}

    public var body: some View {
        @Bindable var accounts = accounts
        AdaptiveList {}
            .fontDesign(.rounded)
            .errorAlert($accounts.error)
            .task(id: session.generation) {
                accounts.load()
                await session.refreshAvailability()
            }
            .navigationTitle("Accounts")
    }
}
