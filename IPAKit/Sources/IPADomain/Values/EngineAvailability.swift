import Foundation

public enum EngineAvailability: String, Hashable, Sendable {
    case ready, needsJIT, unsupported
}
