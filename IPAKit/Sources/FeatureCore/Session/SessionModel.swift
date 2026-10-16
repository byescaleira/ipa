import IPADomain
import Observation

@MainActor @Observable
public final class SessionModel {
    public let repositories: Repositories
    public let services: StoreServices
    public private(set) var generation = 0
    public private(set) var availability: EngineAvailability = .ready

    public init(repositories: Repositories, services: StoreServices) {
        self.repositories = repositories
        self.services = services
    }

    public func reload() {
        generation += 1
    }

    public func refreshAvailability() async {
        availability = await services.engine.availability()
    }
}
