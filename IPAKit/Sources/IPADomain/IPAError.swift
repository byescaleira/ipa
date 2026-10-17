import Foundation

public enum IPAError: Error, LocalizedError, Hashable, Sendable {
    case onFetch, onSave, onRemove
    case invalidInput(String)
    case missingRecord
    case persistence(String)
    case codeRequired
    case signInFailed(String)
    case sessionExpired
    case paidApp
    case licenseRequired
    case appNotFound
    case engine(EngineAvailability)
    case network
    case store(String)

    public var errorDescription: String? {
        switch self {
        case .onFetch: String(appLocalized: "Couldn't load the data. Try again.")
        case .onSave: String(appLocalized: "Couldn't save. Check the fields and try again.")
        case .onRemove: String(appLocalized: "Couldn't delete. Check the linked records.")
        case .invalidInput(let message), .persistence(let message), .signInFailed(let message),
            .store(let message):
            message
        case .missingRecord: String(appLocalized: "This record no longer exists. Refresh the list.")
        case .codeRequired:
            String(appLocalized: "Enter the six-digit code Apple sent to your devices.")
        case .sessionExpired:
            String(
                appLocalized:
                    "Your App Store sign-in expired. Open Accounts, add this Apple ID again, then download."
            )
        case .paidApp: String(appLocalized: "Only free apps can be downloaded.")
        case .licenseRequired:
            String(appLocalized: "This account doesn't have this app yet. Get it first.")
        case .appNotFound: String(appLocalized: "This app isn't available in the selected store.")
        case .engine(.needsJIT):
            String(appLocalized: "The store engine needs JIT on this device. See the JIT guide.")
        case .engine:
            String(appLocalized: "The store engine isn't available on this device.")
        case .network: String(appLocalized: "Couldn't reach the App Store. Check the connection.")
        }
    }
}
