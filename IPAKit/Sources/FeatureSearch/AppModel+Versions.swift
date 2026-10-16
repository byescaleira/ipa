import FeatureCore
import Foundation
import IPADomain

extension AppModel {
    public static let versionIDLength = 1...19

    public var isShowingVersions: Bool { versionsStatus != .idle }

    public var versionID: String { versionIDText.trimmingCharacters(in: .whitespacesAndNewlines) }

    public var isVersionIDValid: Bool {
        Self.versionIDLength.contains(versionID.count) && versionID.allSatisfy(\.isASCII)
            && versionID.allSatisfy(\.isNumber) && (Int64(versionID) ?? 0) > 0
    }

    public var isVersionIDInvalid: Bool { !versionID.isEmpty && !isVersionIDValid }

    public var canDownloadVersionID: Bool { canDownload && isVersionIDValid }

    func loadVersions() async {
        versionsRequest += 1
        let current = versionsRequest
        resetMetadata()
        guard let app, app.isFree, session.availability == .ready,
            let account = accounts.active
        else {
            setVersionIDs([])
            versionsStatus = .idle
            return
        }
        if versionIDs.isEmpty { versionsStatus = .loading }
        do {
            let ids = try await session.services.engine.versions(of: app, for: account)
            try Task.checkCancellation()
            guard current == versionsRequest else { return }
            setVersionIDs(ids)
            versionsStatus = .loaded
        } catch is CancellationError {} catch {
            guard current == versionsRequest, !Task.isCancelled else { return }
            versionsStatus = .failed(error as? IPAError ?? .onFetch)
        }
    }

    public func reloadVersions() async {
        await loadVersions()
    }

    public func requestMetadata(for externalID: String) {
        guard versions[externalID] == nil, !requestedMetadata.contains(externalID),
            let app, let account = accounts.active
        else { return }
        requestedMetadata.insert(externalID)
        pendingMetadata.append(externalID)
        guard metadataTask == nil else { return }
        let generation = versionsRequest
        metadataTask = Task { [weak self] in
            await self?.drainMetadata(app: app, account: account, generation: generation)
        }
    }

    private func drainMetadata(app: StoreApp, account: Account, generation: Int) async {
        let engine = session.services.engine
        while !pendingMetadata.isEmpty, generation == versionsRequest, !Task.isCancelled {
            let batch = Array(pendingMetadata.prefix(batchSize))
            pendingMetadata.removeFirst(batch.count)
            let loaded = await Self.metadata(batch, of: app, for: account, engine: engine)
            guard generation == versionsRequest, !Task.isCancelled else { return }
            for version in loaded { versions[version.externalID] = version }
            requestedMetadata.subtract(batch.filter { versions[$0] == nil })
        }
        if generation == versionsRequest { metadataTask = nil }
    }

    private func resetMetadata() {
        metadataTask?.cancel()
        metadataTask = nil
        pendingMetadata = []
        requestedMetadata = []
    }

    nonisolated private static func metadata(
        _ ids: [String], of app: StoreApp, for account: Account, engine: any StoreEngine
    ) async -> [AppVersion] {
        await withTaskGroup(of: AppVersion?.self) { group in
            for id in ids {
                group.addTask { try? await engine.version(id, of: app, for: account) }
            }
            var loaded: [AppVersion] = []
            for await version in group {
                if let version { loaded.append(version) }
            }
            return loaded
        }
    }
}
