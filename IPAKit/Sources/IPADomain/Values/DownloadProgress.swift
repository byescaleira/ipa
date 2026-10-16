import Foundation

public enum DownloadPhase: String, Hashable, Sendable, Codable {
    case preparing, licensing, downloading, signing
}

public struct DownloadProgress: Hashable, Sendable {
    public let phase: DownloadPhase
    public let completedBytes: Int64
    public let totalBytes: Int64

    public init(phase: DownloadPhase, completedBytes: Int64 = 0, totalBytes: Int64 = 0) {
        self.phase = phase
        self.completedBytes = max(completedBytes, 0)
        self.totalBytes = max(totalBytes, 0)
    }

    public var fraction: Double? {
        guard phase == .downloading, totalBytes > 0 else { return nil }
        return min(Double(completedBytes) / Double(totalBytes), 1)
    }
}
