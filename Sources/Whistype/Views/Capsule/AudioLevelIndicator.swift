import SwiftUI

struct AudioLevelIndicator: View {
    let level: Float
    private let barCount = 7

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { index in
                AudioBar(level: level, index: index, total: barCount)
            }
        }
        .frame(width: 36, height: 24)
    }
}

private struct AudioBar: View {
    let level: Float
    let index: Int
    let total: Int

    @State private var animatedHeight: CGFloat = 3

    private var barColor: Color {
        let position = CGFloat(index) / CGFloat(total - 1)
        return Color(
            hue: 0.55 + position * 0.08,
            saturation: 0.6,
            brightness: 0.95
        )
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(barColor.opacity(0.85))
            .frame(width: 3, height: animatedHeight)
            .onChange(of: level) { _, newLevel in
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 12)) {
                    animatedHeight = computeHeight(for: newLevel)
                }
            }
    }

    private func computeHeight(for level: Float) -> CGFloat {
        let clamped = min(max(CGFloat(level) * 10, 0), 1.0)
        let phase = Double(index) * 0.9 + Double(level) * 25
        let variation = sin(phase) * 0.35 + 0.65
        let height = 3 + clamped * 19 * CGFloat(variation)
        return max(3, min(height, 22))
    }
}
