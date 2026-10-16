import Foundation

public struct DeviceIdentity: Hashable, Sendable, Codable {
    public let bytes: [UInt8]

    public init?(bytes: [UInt8]) {
        guard bytes.count == 6 else { return nil }
        self.bytes = bytes
    }

    public static func random<Generator: RandomNumberGenerator>(using generator: inout Generator)
        -> DeviceIdentity
    {
        var bytes = (0..<6).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        bytes[0] = (bytes[0] | 0x02) & 0xFE
        return DeviceIdentity(unchecked: bytes)
    }

    public static func random() -> DeviceIdentity {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    public var macAddress: String {
        bytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    public var guid: String {
        bytes.map { String(format: "%02X", $0) }.joined()
    }

    private init(unchecked bytes: [UInt8]) {
        self.bytes = bytes
    }
}
