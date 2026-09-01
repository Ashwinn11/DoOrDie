import SwiftUI

/// A clean, cardless Victory illustration featuring the overhead press athlete SVG
/// floating directly on the canvas with golden sunburst rays, laurels, and sparkling stars.
struct VictoryEmblemView: View {
    var size: CGFloat = 200

    @State private var sunburstRotation: Double = 0
    @State private var auraPulse = false
    @State private var starTwinkle = false

    private let victoryFrames = ["ex-overhead-press-1", "ex-overhead-press-2", "ex-overhead-press-3"]

    var body: some View {
        ZStack {
            // 1. Ambient Coral Aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DoTheme.Color.coral.opacity(0.25),
                            DoTheme.Color.coral.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: size * 0.95
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .scaleEffect(auraPulse ? 1.15 : 0.95)
                .animation(
                    .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: auraPulse
                )

            // 2. Rotating Sunburst Rays
            SunburstRays(radius: size * 0.85)
                .rotationEffect(.degrees(sunburstRotation))
                .opacity(0.22)
                .animation(
                    .linear(duration: 22).repeatForever(autoreverses: false),
                    value: sunburstRotation
                )

            // 3. Laurels framing the athlete
            HStack(spacing: size * 0.9) {
                Image(systemName: "laurel.leading")
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(DoTheme.Color.coral.opacity(0.8))
                Image(systemName: "laurel.trailing")
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(DoTheme.Color.coral.opacity(0.8))
            }

            // 4. Cardless Floating Overhead Press Lifter SVG in Coral
            CyclingSVGView(frameImageNames: victoryFrames, interval: 0.5)
                .foregroundStyle(DoTheme.Color.coral)
                .frame(width: size * 1.1, height: size * 0.95)
                .shadow(color: DoTheme.Color.coral.opacity(0.3), radius: 16, y: 6)

            // 5. Sparkle Stars
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.16, weight: .bold))
                .foregroundStyle(DoTheme.Color.coral)
                .offset(x: size * 0.42, y: -size * 0.36)
                .scaleEffect(starTwinkle ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: starTwinkle)
        }
        .frame(width: size * 1.8, height: size * 1.4)
        .onAppear {
            sunburstRotation = 360
            auraPulse = true
            starTwinkle = true
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
