import IPADesignSystem
import IPADomain
import SwiftUI

struct EngineStatus: Hashable {
    let availability: EngineAvailability

    init(_ availability: EngineAvailability) {
        self.availability = availability
    }

    var title: String { availability.title }

    var detail: String { availability.detail }

    var symbol: String { availability.symbol }

    var color: Color { availability.color }

    var needsGuide: Bool { availability.needsGuide }
}
