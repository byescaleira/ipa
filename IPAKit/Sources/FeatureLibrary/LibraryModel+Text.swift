import FeatureCore
import Foundation
import IPADomain

extension LibraryModel {
    public var heroChip: String { String(appLocalized: "On This Device").uppercased() }

    public var heroTitle: String { String(appLocalized: "\(packageCount) packages") }

    public var heroCaption: String {
        String(appLocalized: "\(ByteCount.text(totalBytes)) used")
    }

    public var filteredOutText: String {
        let query = text.trimmingCharacters(in: .whitespaces)
        return String(appLocalized: "No packages match “\(query)”.")
    }

    public var inProgressFooter: String {
        String(appLocalized: "Keep IPA open until each download finishes.")
    }

    public func footer(for group: LibraryGroup) -> String {
        let records = downloads.records
        guard Set(records.map(\.accountEmail)).count > 1 else { return group.email }
        let bytes = records.filter { $0.accountEmail == group.email }.reduce(0) {
            $0 + $1.sizeBytes
        }
        return "\(group.email) · \(ByteCount.text(bytes))"
    }

    public func caption(for record: DownloadRecord) -> String {
        "\(record.detailLine) · \(record.dateText)"
    }

    public func versionText(for task: DownloadTask) -> String {
        if !task.version.isEmpty { return String(appLocalized: "v\(task.version)") }
        guard let id = task.externalVersionID else { return "" }
        return String(appLocalized: "Version ID \(id)")
    }

    public func statusText(for task: DownloadTask) -> String {
        if let failure = task.failure { return failure.localizedDescription }
        return [task.progress.phaseText, task.progress.bytesText].compactMap(\.self)
            .joined(separator: " · ")
    }

    public var deletionTitle: String {
        guard let deletion else { return "" }
        return String(appLocalized: "Delete \(deletion.name)?")
    }

    public var deletionMessage: String {
        String(
            appLocalized:
                "The package leaves this device and the Files app. You can download it again from Search."
        )
    }

    public var examples: [LibraryExample] {
        [
            LibraryExample(
                record: sample("YouTube", "20.19.2", 215_744_102, hoursAgo: 2),
                symbol: "play.rectangle.fill", color: .rust),
            LibraryExample(
                record: sample("Spotify", "9.0.50", 198_705_152, hoursAgo: 26),
                symbol: "music.note", color: .olive),
        ]
    }

    private func sample(_ name: String, _ version: String, _ bytes: Int64, hoursAgo: Double)
        -> DownloadRecord
    {
        DownloadRecord(
            id: name, accountEmail: "", appID: 0, bundleID: "", name: name, version: version,
            fileName: "", sizeBytes: bytes,
            downloadedAt: Date.now.addingTimeInterval(-hoursAgo * 3_600))
    }
}

public struct LibraryExample: Identifiable, Hashable, Sendable {
    public let record: DownloadRecord
    public let symbol: String
    public let color: RetroColor

    public var id: String { record.id }
}
