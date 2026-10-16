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
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.0")
    ],
    targets: [
        .target(name: "IPADomain"),
        .target(name: "IPAData", dependencies: ["IPADomain"]),
        .target(name: "IPADesignSystem"),
        .target(name: "IPAResource", resources: [.process("Assets")]),
        .target(name: "IPAMock", dependencies: ["IPADomain"]),
        .binaryTarget(name: "IPAToolCore", path: "Frameworks/IPAToolCore.xcframework"),
        .target(
            name: "IPAEngine",
            dependencies: [
                "IPADomain",
                .target(name: "IPAToolCore", condition: .when(platforms: [.iOS])),
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-export_dynamic"], .when(platforms: [.iOS]))
            ]),
        .target(
            name: "FeatureCore",
            dependencies: [
                "IPADomain", "IPADesignSystem", "IPAResource",
                .product(name: "Lottie", package: "lottie-spm"),
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
                "IPADomain", "IPAData", "IPADesignSystem", "IPAEngine", "IPAMock", "FeatureCore",
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
