import Foundation
import IPADomain

public enum AppIcon: String, CaseIterable, Identifiable, Sendable {
    case standard

    public var id: String { rawValue }

    public init(assetName: String?) {
        self = Self.allCases.first { $0.assetName == assetName } ?? .standard
    }

    public var assetName: String? {
        switch self {
        case .standard: nil
        }
    }

    public var previewName: String { assetName ?? "IPAIcon" }

    public var title: String {
        switch self {
        case .standard: String(appLocalized: "Classic")
        }
    }
}
