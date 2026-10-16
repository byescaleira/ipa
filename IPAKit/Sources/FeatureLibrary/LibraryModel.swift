import FeatureCore
import Foundation
import IPADomain
import Observation

#if os(macOS)
    import AppKit
#endif

@MainActor @Observable
public final class LibraryModel {
    public var text = ""
    public var deletion: DownloadRecord?
    @ObservationIgnored let downloads: DownloadCenter
    @ObservationIgnored let accounts: AccountsModel

    public init(downloads: DownloadCenter, accounts: AccountsModel) {
        self.downloads = downloads
        self.accounts = accounts
    }

    public var isShowingEmptyState: Bool { downloads.isEmpty }

    public var isFiltering: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty }

    public var hasRecords: Bool { !downloads.records.isEmpty }

    public var packageCount: Int { downloads.records.count }

    public var totalBytes: Int64 { downloads.records.reduce(0) { $0 + $1.sizeBytes } }

    public var tasks: [DownloadTask] {
        downloads.tasks.filter { matches($0.app) }
    }

    public var groups: [LibraryGroup] {
        let records = downloads.records.filter { $0.matches(text) }
        let byEmail = Dictionary(grouping: records, by: \.accountEmail)
        let known = accounts.accounts.map(\.email)
        let order = [accounts.active?.email].compactMap(\.self) + known
        let unknown = byEmail.keys.filter { !known.contains($0) }.sorted()
        var seen = Set<String>()
        return (order + unknown).compactMap { email in
            guard seen.insert(email).inserted, let items = byEmail[email] else { return nil }
            let account = accounts.accounts.first { $0.email == email }
            return LibraryGroup(
                email: email, title: account?.displayName ?? email,
                records: items.sorted { $0.downloadedAt > $1.downloadedAt })
        }
    }

    public var isFilteredOut: Bool { isFiltering && groups.isEmpty && tasks.isEmpty }

    public func progress(for task: DownloadTask) -> Double {
        switch task.progress.phase {
        case .downloading: task.progress.fraction ?? 0
        case .signing: 1
        case .preparing, .licensing: 0
        }
    }

    public var isConfirmingDeletion: Bool {
        get { deletion != nil }
        set { if !newValue { deletion = nil } }
    }

    public func fileURL(for record: DownloadRecord) -> URL {
        downloads.fileURL(for: record)
    }

    public func load() async {
        await downloads.load()
    }

    public func retry(_ task: DownloadTask) {
        downloads.retry(task)
    }

    public func cancel(_ task: DownloadTask) {
        downloads.cancel(task)
    }

    public func confirmDeletion() async {
        guard let deletion else { return }
        self.deletion = nil
        await downloads.delete(deletion)
    }

    #if os(macOS)
        public func reveal(_ record: DownloadRecord) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL(for: record)])
        }
    #endif

    private func matches(_ app: StoreApp) -> Bool {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        return app.name.localizedStandardContains(query)
            || app.bundleID.localizedStandardContains(query)
    }
}

public struct LibraryGroup: Identifiable, Hashable, Sendable {
    public let email: String
    public let title: String
    public let records: [DownloadRecord]

    public var id: String { email }

    public var totalBytes: Int64 { records.reduce(0) { $0 + $1.sizeBytes } }
}
