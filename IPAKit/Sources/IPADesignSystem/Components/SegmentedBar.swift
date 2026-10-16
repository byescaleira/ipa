import SwiftUI

public struct SegmentedBar: View {
    private let count: Int
    private let value: Double
    private let color: Color

    public init(count: Int, value: Double, color: Color) {
        self.count = count
        self.value = value
        self.color = color
    }

    public var body: some View {
        HStack(spacing: .spaceS) {
            ForEach(0..<count, id: \.self) { index in
                ProgressView(value: min(max(value - Double(index), 0), 1), total: 1)
                    .tint(color)
            }
        }
        .accessibilityHidden(true)
    }
}
