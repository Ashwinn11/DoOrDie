import SwiftUI

/// Unified Soft Palette and Liquid Glass design system tokens for Do or Die.
enum DoTheme {
    enum Color {
        /// Ultra-clean, airy canvas
        static let bg = SwiftUI.Color(hex: 0xFBFBFB)
        /// Deep soft charcoal text & headings
        static let ink = SwiftUI.Color(hex: 0x1C1C1E)
        static let gameInk = SwiftUI.Color(hex: 0x1C1C1E)
        /// Clean secondary/helper text
        static let muted = SwiftUI.Color(hex: 0x737373)
        static let mutedOnDark = SwiftUI.Color.white.opacity(0.7)

        /// Primary Action Accent: Warm Sunset Coral
        static let coral = SwiftUI.Color(hex: 0xF06560)
        static let comb = coral

        /// Onboarding & Progress Accent: Soft Lilac / Mauve
        static let lilac = SwiftUI.Color(hex: 0xBA79AF)

        /// Alias for completed/reward moments (now maps to Coral/Lilac - zero yellow)
        static let honey = coral
        static let gold = coral

        /// Pure White Surface
        static let shell = SwiftUI.Color(hex: 0xFFFFFF)
        static let pillGray = SwiftUI.Color(hex: 0xF2F2F5)

        /// Text/icon color on saturated or colored surfaces
        static let onDark = SwiftUI.Color.white
        /// Hairline borders
        static let borderOnDark = SwiftUI.Color.white.opacity(0.18)
        static let borderOnLight = SwiftUI.Color.black.opacity(0.04)

        static let liveGradient = LinearGradient(
            colors: [
                SwiftUI.Color(hex: 0xF06560),
                SwiftUI.Color(hex: 0xBA79AF),
                SwiftUI.Color(hex: 0xF06560),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Radius {
        static let compact: CGFloat = 12
        static let card: CGFloat = 24
        static let button: CGFloat = 28
        static let pill: CGFloat = 26
    }

    enum Shadow {
        static let resting = (color: SwiftUI.Color.black.opacity(0.04), radius: CGFloat(8), y: CGFloat(3))
        static let elevated = (color: SwiftUI.Color.black.opacity(0.08), radius: CGFloat(16), y: CGFloat(6))
        static let liquidGlass = (color: SwiftUI.Color.black.opacity(0.06), radius: CGFloat(14), y: CGFloat(6))
    }

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 12
        static let md: CGFloat = 20
        static let lg: CGFloat = 28
        static let xl: CGFloat = 40
    }

    enum Motion {
        /// Strong custom ease-out (220ms) for responsive UI entrances
        static let easeOut = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.22)
        /// Quick snappy transition (160ms) for toggles & selections
        static let snappy = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.16)
        /// iOS-like drawer / sheet curve
        static let easeDrawer = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.32)

        /// Apple-style physical spring presets
        static let springPress = Animation.spring(response: 0.20, dampingFraction: 0.72)
        static let springInteractive = Animation.spring(response: 0.28, dampingFraction: 0.74)
        static let springDelight = Animation.spring(response: 0.42, dampingFraction: 0.64)
    }

    enum Typography {
        static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        }

        static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        }

        static let hero = display(38, weight: .bold)
        static let title = display(24, weight: .bold)
        static let headline = display(18, weight: .semibold)
        static let streakNumber = display(58, weight: .heavy)
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

struct TightTracking: ViewModifier {
    let size: CGFloat
    func body(content: Content) -> some View {
        content.tracking(-size * 0.02)
    }
}

#if canImport(UIKit)
import UIKit
#endif

/// Emil Kowalski tactile press feedback ButtonStyle (scale on press with spring recovery and light haptic)
public struct PressableScaleButtonStyle: ButtonStyle {
    public var scale: CGFloat = 0.97

    public init(scale: CGFloat = 0.97) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(DoTheme.Motion.springPress, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    #if canImport(UIKit)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    #endif
                }
            }
    }
}

extension ButtonStyle where Self == PressableScaleButtonStyle {
    public static var pressable: PressableScaleButtonStyle {
        PressableScaleButtonStyle()
    }
    public static func pressable(scale: CGFloat) -> PressableScaleButtonStyle {
        PressableScaleButtonStyle(scale: scale)
    }
}

extension View {
    func displayTracking(_ size: CGFloat) -> some View {
        modifier(TightTracking(size: size))
    }

    func doShadow(_ style: (color: Color, radius: CGFloat, y: CGFloat)) -> some View {
        shadow(color: style.color, radius: style.radius, y: style.y)
    }

    /// Floating Liquid Glass card styling with soft specular highlights and two-layer ambient elevation
    func liquidGlassCard(padding: CGFloat = DoTheme.Space.md) -> some View {
        self
            .padding(padding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                        .fill(Color.white.opacity(0.96))

                    RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )

                    RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.5), Color.black.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.07), radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    /// Floating Liquid Glass selection pill styling matching reference
    func liquidGlassPill(isSelected: Bool = false) -> some View {
        self
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.white.opacity(0.96))

                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.5),
                                    Color.black.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            }
            .shadow(
                color: Color.black.opacity(isSelected ? 0.09 : 0.06),
                radius: isSelected ? 18 : 12,
                x: 0,
                y: isSelected ? 8 : 6
            )
            .shadow(
                color: Color.black.opacity(0.03),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}
