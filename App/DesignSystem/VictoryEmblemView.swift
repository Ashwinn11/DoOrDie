import SwiftUI

/// A rich, animated Victory illustration featuring the app's official Bryllim athlete figure:
/// - Rotating golden sunburst light rays
/// - Twinkling star sparkles
/// - Triumphant lifter locking out the overhead barbell press with golden laurels
struct VictoryEmblemView: View {
    var size: CGFloat = 160

    @State private var sunburstRotation: Double = 0
    @State private var auraPulse = false
    @State private var shineOffset: CGFloat = -1
    @State private var starTwinkle = false

    private let victoryFrames = ["ex-overhead-press-1", "ex-overhead-press-2", "ex-overhead-press-3"]

    var body: some View {
        ZStack {
            // 1. Ambient Golden Aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DoTheme.Color.gold.opacity(0.45),
                            DoTheme.Color.gold.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.95
                    )
                )
                .frame(width: size * 1.9, height: size * 1.9)
                .scaleEffect(auraPulse ? 1.15 : 0.95)
                .animation(
                    .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: auraPulse
                )

            // 2. Rotating Sunburst Rays
            SunburstRays(radius: size * 0.9)
                .rotationEffect(.degrees(sunburstRotation))
                .opacity(0.35)
                .animation(
                    .linear(duration: 20).repeatForever(autoreverses: false),
                    value: sunburstRotation
                )

            // 3. Central Dark/Gold Trophy Crest
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                DoTheme.Color.gameInk,
                                DoTheme.Color.gameInk,
                                DoTheme.Color.gold.opacity(0.25)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 1.25, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        DoTheme.Color.gold,
                                        DoTheme.Color.gold.opacity(0.4),
                                        Color(hex: 0x8A6D14)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: DoTheme.Color.gold.opacity(0.4), radius: 20, y: 6)

                // 4. Golden Laurels framing the athlete
                HStack(spacing: size * 0.8) {
                    Image(systemName: "laurel.leading")
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(DoTheme.Color.gold.opacity(0.7))
                    Image(systemName: "laurel.trailing")
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(DoTheme.Color.gold.opacity(0.7))
                }

                // 5. Bryllim Athlete SVG in Triumphant Overhead Press
                CyclingSVGView(frameImageNames: victoryFrames, interval: 0.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                DoTheme.Color.gold,
                                Color(hex: 0xD49400)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.95, height: size * 0.78)

                // 6. Sparkle Star Crown
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .offset(x: size * 0.38, y: -size * 0.34)
                    .scaleEffect(starTwinkle ? 1.3 : 0.7)
                    .opacity(starTwinkle ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: starTwinkle
                    )

                // 7. Diagonal sweeping shine highlight
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .white.opacity(0.28), location: 0.5),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 1.25, height: size)
                    .offset(x: shineOffset * size * 1.5)
                    .mask(
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .frame(width: size * 1.25, height: size)
                    )
            }
        }
        .frame(width: size * 1.9, height: size * 1.5)
        .onAppear {
            sunburstRotation = 360
            auraPulse = true
            starTwinkle = true
            withAnimation(
                .easeInOut(duration: 2.5).repeatForever(autoreverses: false).delay(0.5)
            ) {
                shineOffset = 1
            }
        }
    }
}

// MARK: - Sunburst Rays

private struct SunburstRays: View {
    let radius: CGFloat
    let rayCount: Int = 12

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let angleStep = (Double.pi * 2) / Double(rayCount)

            for i in 0..<rayCount {
                let startAngle = Double(i) * angleStep
                let endAngle = startAngle + (angleStep * 0.45)

                var path = Path()
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: Angle(radians: startAngle),
                    endAngle: Angle(radians: endAngle),
                    clockwise: false
                )
                path.closeSubpath()

                context.fill(
                    path,
                    with: .color(DoTheme.Color.gold)
                )
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        DoTheme.Color.bg.ignoresSafeArea()
        VictoryEmblemView()
    }
}
