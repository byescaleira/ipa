import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class DownloadCenter {
    public private(set) var tasks: [DownloadTask] = []
    public private(set) var records: [DownloadRecord] = []
    public private(set) var hasLoaded = false
    public var error: IPAError?
    @ObservationIgnored private let repositories: Repositories
    @ObservationIgnored private let services: StoreServices
    @ObservationIgnored private var running: [String: Task<Void, Never>] = [:]

    public init(repositories: Repositories, services: StoreServices) {
        self.repositories = repositories
        self.services = services
    }

    public var isEmpty: Bool { hasLoaded && records.isEmpty && tasks.isEmpty }

    public func load() async {
        do {
            records = try await repositories.downloads.records()
            hasLoaded = true
        } catch is CancellationError {} catch {
            self.error = error as? IPAError ?? .onFetch
        }
    }

    public func task(for app: StoreApp) -> DownloadTask? {
        tasks.first { $0.app.id == app.id && $0.failure == nil }
    }

    public func fileURL(for record: DownloadRecord) -> URL {
        services.folder.fileURL(for: record)
    }

    @discardableResult
    public func start(
        _ app: StoreApp, version: AppVersion? = nil, externalVersionID: String? = nil,
        account: Account
    ) -> DownloadTask {
        let task = DownloadTask(
            app: app, account: account,
            externalVersionID: version?.externalID ?? externalVersionID,
            version: version?.displayVersion ?? (externalVersionID == nil ? app.version : ""))
        tasks.append(task)
        run(task)
        return task
    }

    public func retry(_ task: DownloadTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].failure = nil
        tasks[index].progress = DownloadProgress(phase: .preparing)
        run(tasks[index])
    }

    public func cancel(_ task: DownloadTask) {
        running[task.id]?.cancel()
        running[task.id] = nil
        tasks.removeAll { $0.id == task.id }
    }

    public func delete(_ record: DownloadRecord) async {
        do {
            try services.folder.remove(record)
            try await repositories.downloads.delete(id: record.id)
            records.removeAll { $0.id == record.id }
        } catch {
            self.error = error as? IPAError ?? .onRemove
        }
    }

    public func deleteAll() async {
        for task in tasks { cancel(task) }
        do {
            try services.folder.removeAll()
            try await repositories.downloads.deleteAll()
            records = []
        } catch {
            self.error = error as? IPAError ?? .onRemove
        }
    }

    private func run(_ task: DownloadTask) {
        running[task.id] = Task { [weak self] in
            await self?.perform(task)
        }
    }

    private func perform(_ task: DownloadTask) async {
        do {
            let destination = try services.folder.prepareFolder(for: task.account.email)
            let request = DownloadRequest(
                app: task.app, account: task.account, externalVersionID: task.externalVersionID,
                destination: destination)
            let package = try await download(request, taskID: task.id)
            let record = DownloadRecord(
                accountEmail: task.account.email, appID: task.app.id, bundleID: task.app.bundleID,
                name: task.app.name, version: package.version,
                externalVersionID: task.externalVersionID,
                fileName: package.fileURL.lastPathComponent, sizeBytes: package.sizeBytes,
                artworkURL: task.app.artworkURL)
            try await repositories.downloads.save(record)
            records.removeAll {
                $0.fileName == record.fileName && $0.accountEmail == record.accountEmail
            }
            records.insert(record, at: 0)
            tasks.removeAll { $0.id == task.id }
        } catch is CancellationError {
            tasks.removeAll { $0.id == task.id }
        } catch {
            fail(task.id, error as? IPAError ?? .store(error.localizedDescription))
        }
        running[task.id] = nil
    }

    private func download(_ request: DownloadRequest, taskID: String) async throws
        -> DownloadedPackage
    {
        let engine = services.engine
        let report: @Sendable (DownloadProgress) -> Void = { [weak self] progress in
            Task { @MainActor in self?.update(taskID, progress) }
        }
        do {
            return try await engine.download(request, progress: report)
        } catch IPAError.licenseRequired {
            guard request.app.isFree else { throw IPAError.paidApp }
            update(taskID, DownloadProgress(phase: .licensing))
            try await engine.purchase(request.app, for: request.account)
            return try await engine.download(request, progress: report)
        }
    }

    private func update(_ id: String, _ progress: DownloadProgress) {
        guard let index = tasks.firstIndex(where: { $0.id == id }), tasks[index].failure == nil
        else { return }
        tasks[index].progress = progress
    }

    private func fail(_ id: String, _ failure: IPAError) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].failure = failure
    }
}
