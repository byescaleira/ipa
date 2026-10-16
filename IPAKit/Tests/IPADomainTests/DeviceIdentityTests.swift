import IPADomain
import Testing

struct DeviceIdentityTests {
    @Test func generatesALocallyAdministeredUnicastAddress() {
        for _ in 0..<50 {
            let identity = DeviceIdentity.random()
            #expect(identity.bytes.count == 6)
            #expect(identity.bytes[0] & 0x02 == 0x02)
            #expect(identity.bytes[0] & 0x01 == 0)
        }
    }

    @Test func formatsTheAddressAndGUID() throws {
        let identity = try #require(DeviceIdentity(bytes: [0x02, 0xAB, 0x0C, 0x10, 0xFF, 0x01]))
        #expect(identity.macAddress == "02:AB:0C:10:FF:01")
        #expect(identity.guid == "02AB0C10FF01")
    }

    @Test func rejectsTheWrongLength() {
        #expect(DeviceIdentity(bytes: [1, 2, 3]) == nil)
    }
}
