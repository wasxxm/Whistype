import SwiftUI

struct KeyCapView: View {
    let text: String
    var size: KeyCapSize = .regular

    enum KeyCapSize {
        case small, regular

        var font: Font {
            switch self {
            case .small: .system(.caption, design: .rounded, weight: .medium)
            case .regular: .system(.title3, design: .rounded, weight: .medium)
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: 7
            case .regular: 12
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: 3
            case .regular: 6
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: 4
            case .regular: 6
            }
        }
    }

    var body: some View {
        Text(text)
            .font(size.font)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
    }
}
