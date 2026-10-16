import Foundation
import IPADomain

extension Storefront {
    public var name: String { name(locale: .app) }

    public var title: String { "\(flag) \(name)" }
}
