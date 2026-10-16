import FeatureCore
import IPADesignSystem
import IPADomain
import SwiftUI

struct EngineStatusRows: View {
    @Environment(\.showGuide) private var showGuide
    let status: EngineStatus

    init(_ availability: EngineAvailability) {
        status = EngineStatus(availability)
    }

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge(status.symbol, color: status.color, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(verbatim: status.title)
                    .font(.rowTitle)
                    .foregroundStyle(status.color)
                Text(verbatim: status.detail).font(.rowDetail).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
        if status.needsGuide, let showGuide {
            Button {
                showGuide(.jit)
            } label: {
                Label {
                    Text(verbatim: Guide.jit.title)
                } icon: {
                    Image(systemName: Guide.jit.systemImage)
                }
                .font(.buttonLabel)
            }
        }
    }
}
