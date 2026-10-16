import SwiftUI

public enum IPAResourceImage {
    public static func appIcon(_ name: String) -> Image {
        Image(name, bundle: .module)
    }
}
