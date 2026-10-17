import Foundation
import IPADomain

enum JITStatus {
    static var availability: EngineAvailability {
        #if os(iOS)
            isDebugged ? .ready : .needsJIT
        #else
            .unsupported
        #endif
    }

    #if os(iOS)
        private static var isDebugged: Bool {
            var flags: UInt32 = 0
            let result = csops(getpid(), csOpsStatus, &flags, MemoryLayout<UInt32>.size)
            guard result == 0 else { return false }
            return flags & csDebugged != 0
        }

        private static let csOpsStatus: UInt32 = 0
        private static let csDebugged: UInt32 = 0x1000_0000
    #endif
}

#if os(iOS)
    @_silgen_name("csops")
    private func csops(
        _ pid: Int32, _ ops: UInt32, _ useraddr: UnsafeMutableRawPointer, _ usersize: Int
    )
        -> Int32
#endif
