import SwiftUI

struct AudioLevelIndicator: View {
    let level: Float
    let barCount = 5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                AudioBar(level: level, index: index, total: barCount)
            }
        }
        .frame(width: 30, height: 24)
    }
}

private struct AudioBar: View {
    let level: Float
    let index: Int
    let total: Int

    @State private var animatedHeight: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.white.opacity(0.9))
            .frame(width: 3, height: animatedHeight)
            .onChange(of: level) { _, newLevel in
                withAnimation(.easeOut(duration: 0.08)) {
                    animatedHeight = computeHeight(for: newLevel)
                }
            }
    }

    private func computeHeight(for level: Float) -> CGFloat {
        let normalizedLevel = min(max(CGFloat(level) * 8, 0), 1.0)
        let barVariation = sin(Double(index) * 1.2 + Double(level) * 20) * 0.3 + 0.7
        let height = 4 + normalizedLevel * 18 * CGFloat(barVariation)
        return max(4, min(height, 22))
    }
}
