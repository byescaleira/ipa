import IPADomain
import Observation

@MainActor @Observable
public final class EditorStatus {
    public private(set) var isLoaded = false
    public private(set) var isBusy = false
    public private(set) var isSaved = false
    public var error: IPAError?
    @ObservationIgnored private var loadRequest = 0

    public init() {}

    public var isLocked: Bool { isBusy || isSaved }

    public func load(_ work: () async throws -> Void) async {
        guard !isLoaded, !isSaved else { return }
        loadRequest += 1
        let request = loadRequest
        isBusy = true
        error = nil
        defer { if request == loadRequest { isBusy = false } }
        do {
            try await work()
            try Task.checkCancellation()
            if request == loadRequest { isLoaded = true }
        } catch is CancellationError {} catch {
            if request == loadRequest && !Task.isCancelled {
                self.error = error as? IPAError ?? .onFetch
            }
        }
    }

    public func refresh(_ work: () async throws -> Void) async {
        guard isLoaded, !isLocked else { return }
        do { try await work() } catch is CancellationError {} catch {
            if !Task.isCancelled { self.error = error as? IPAError ?? .onFetch }
        }
    }

    public func save(_ work: () async throws -> Void) async {
        await finish(fallback: .onSave, work)
    }

    public func remove(_ work: () async throws -> Void) async {
        await finish(fallback: .onRemove, work)
    }

    private func finish(fallback: IPAError, _ work: () async throws -> Void) async {
        guard isLoaded, !isLocked else { return }
        isBusy = true
        error = nil
        defer { isBusy = false }
        do {
            try await work()
            isSaved = true
        } catch {
            self.error = error as? IPAError ?? fallback
        }
    }
}
