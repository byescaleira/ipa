import Foundation
import IPADomain

public enum ByteCount {
    public static func text(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file).locale(.app))
    }
}
