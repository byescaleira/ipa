// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "IPAKit",
    defaultLocalization: "en",
    platforms: [.iOS("27.0"), .macOS("27.0"), .visionOS("27.0")],
    products: [
        .library(name: "IPAWidgetKit", targets: ["IPADomain", "IPADesignSystem"]),
        .library(
            name: "IPAKit",
            targets: ["IPADomain", "IPAData", "FeatureCore", "FeatureSettings", "AppShell"]),
    ],
    targets: [
        .binaryTarget(
            name: "Lottie",
            url: "https://github.com/airbnb/lottie-ios/releases/download/4.6.1/Lottie.xcframework.zip",
            checksum: "03d3f3b085da9479bcab7b0ad4b6d75a88425d27bf3c7582698fddce14c9181f"),
        .target(name: "IPADomain"),
        .target(name: "IPAData", dependencies: ["IPADomain"]),
        .target(name: "IPADesignSystem"),
        .target(name: "IPAResource", resources: [.process("Assets")]),
        .target(name: "IPAMock", dependencies: ["IPADomain"]),
        .target(
            name: "FeatureCore",
            dependencies: [
                "IPADomain", "IPADesignSystem", "IPAResource",
                "Lottie",
            ]),
        .target(
            name: "FeatureAccounts",
            dependencies: ["IPADomain", "IPADesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureGuides",
            dependencies: ["IPADomain", "IPADesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureLibrary",
            dependencies: ["IPADomain", "IPADesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureSearch",
            dependencies: ["IPADomain", "IPADesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureSettings",
            dependencies: ["IPADomain", "IPADesignSystem", "IPAResource", "FeatureCore"]),
        .target(
            name: "AppShell",
            dependencies: [
                "IPADomain", "IPAData", "IPADesignSystem", "IPAMock", "FeatureCore",
                "FeatureAccounts", "FeatureGuides", "FeatureLibrary", "FeatureSearch",
                "FeatureSettings",
            ]),
        .testTarget(name: "IPADomainTests", dependencies: ["IPADomain"]),
        .testTarget(name: "IPADataTests", dependencies: ["IPADomain", "IPAData"]),
        .testTarget(name: "IPADesignSystemTests", dependencies: ["IPADesignSystem"]),
        .testTarget(name: "IPAResourceTests", dependencies: ["IPAResource"]),
        .testTarget(name: "IPAMockTests", dependencies: ["IPADomain", "IPAMock"]),
        .testTarget(
            name: "FeatureCoreTests",
            dependencies: [
                "IPADomain", "IPAData", "IPADesignSystem", "IPAMock", "IPAResource",
                "FeatureCore",
            ]),
        .testTarget(
            name: "FeatureAccountsTests",
            dependencies: ["IPADomain", "IPAData", "IPAMock", "FeatureCore", "FeatureAccounts"]),
        .testTarget(
            name: "FeatureGuidesTests",
            dependencies: ["IPADomain", "IPAData", "FeatureCore", "FeatureGuides"]),
        .testTarget(
            name: "FeatureLibraryTests",
            dependencies: ["IPADomain", "IPAData", "IPAMock", "FeatureCore", "FeatureLibrary"]),
        .testTarget(
            name: "FeatureSearchTests",
            dependencies: ["IPADomain", "IPAData", "IPAMock", "FeatureCore", "FeatureSearch"]),
        .testTarget(
            name: "FeatureSettingsTests",
            dependencies: ["IPADomain", "IPAData", "FeatureCore", "FeatureSettings"]),
        .testTarget(
            name: "AppShellTests",
            dependencies: ["IPADomain", "IPAData", "FeatureCore", "AppShell"]),
    ]
)
