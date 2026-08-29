import SwiftUI

/// Palette and type ramp lifted from tryclucky.com's computed styles, retuned
/// for Do or Die's higher-stakes tone (comb becomes the dominant accent
/// instead of a highlight).
enum DoTheme {
    enum Color {
        static let bg = SwiftUI.Color(hex: 0xEDEDED)
        static let ink = SwiftUI.Color(hex: 0x000000)
        static let gameInk = SwiftUI.Color(hex: 0x17130E)
        static let muted = SwiftUI.Color(hex: 0x000000, opacity: 0.5)
        static let mutedOnDark = SwiftUI.Color.white.opacity(0.55)
        static let comb = SwiftUI.Color(hex: 0xCC3F02)
        static let gold = SwiftUI.Color(hex: 0xFFC014)
        static let shell = SwiftUI.Color(hex: 0xFFFFFF)
        static let pillGray = SwiftUI.Color(hex: 0xF3F3F3)

        static let liveGradient = LinearGradient(
            colors: [
                SwiftUI.Color(hex: 0x49D8FF),
                SwiftUI.Color(hex: 0x6726F1),
                SwiftUI.Color(hex: 0xFF35A7),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Radius {
        static let pill: CGFloat = 100
        static let card: CGFloat = 28
        static let tile: CGFloat = 20
        static let chip: CGFloat = 14
    }

    enum Space {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 12
        static let md: CGFloat = 20
        static let lg: CGFloat = 28
        static let xl: CGFloat = 40
    }

    enum Motion {
        /// tryclucky.com's --ease-out: cubic-bezier(.23,1,.32,1)
        static let easeOut = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.45)
        static let snappy = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.25)
    }

    enum Typography {
        /// One typeface across the whole app — ui-rounded resolves to SF Pro
        /// Rounded on-device, with zero licensing. `display`/`body` are kept
        /// as separate entry points for size/weight defaults, not fonts.
        static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        static let hero = display(48, weight: .bold)
        static let title = display(28, weight: .bold)
        static let headline = display(20, weight: .semibold)
        static let streakNumber = display(64, weight: .heavy)
    }
}

extension SwiftUI.Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex & 0xFF0000) >> 16) / 255
        let g = Double((hex & 0x00FF00) >> 8) / 255
        let b = Double(hex & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// tryclucky.com's tight display tracking (-1.74px at 58px, ~ -3% of size).
struct TightTracking: ViewModifier {
    let size: CGFloat
    func body(content: Content) -> some View {
        content.tracking(-size * 0.03)
    }
}

extension View {
    func displayTracking(_ size: CGFloat) -> some View {
        modifier(TightTracking(size: size))
    }
}
