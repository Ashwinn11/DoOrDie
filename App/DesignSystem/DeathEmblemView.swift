import SwiftUI

/// A rich, animated Death illustration featuring the app's official Bryllim athlete figure:
/// - Atmospheric breathing combustion aura
/// - Continuous floating ash and flame sparks (TimelineView)
/// - Collapsed / exhausted athlete SVG cycling animation on dark gameInk card
struct DeathEmblemView: View {
    var size: CGFloat = 160

    @State private var auraPulse = false
    @State private var breathingMotion = false

    private let deathFrames = ["ex-defeat-1", "ex-defeat-2", "ex-defeat-3"]

    var body: some View {
        ZStack {
            // 1. Ambient pulsating heatwave glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DoTheme.Color.comb.opacity(0.4),
                            DoTheme.Color.comb.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.9
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .scaleEffect(auraPulse ? 1.15 : 0.92)
                .opacity(auraPulse ? 1.0 : 0.7)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: auraPulse
                )

            // 2. Rising floating fire embers
            EmbersParticleCanvas(width: size * 1.6, height: size * 1.6)

            // 3. Central Dark Badge with glowing comb outline
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                DoTheme.Color.gameInk,
                                DoTheme.Color.gameInk,
                                DoTheme.Color.comb.opacity(0.2)
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
                                        DoTheme.Color.comb,
                                        DoTheme.Color.comb.opacity(0.4),
                                        Color.black
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: DoTheme.Color.comb.opacity(0.35), radius: 18, y: 6)

                // 4. Bryllim Athlete SVG in Collapsed / Surrender Pose
                VStack(spacing: 0) {
                    ZStack {
                        CyclingSVGView(frameImageNames: deathFrames, interval: 0.6)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        .white,
                                        Color(hex: 0xF3F3F3),
                                        DoTheme.Color.comb.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: size * 0.95, height: size * 0.75)
                            .scaleEffect(breathingMotion ? 1.02 : 0.98)
                            .animation(
                                .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                                value: breathingMotion
                            )
                    }
                }
            }
        }
        .frame(width: size * 1.8, height: size * 1.5)
        .onAppear {
            auraPulse = true
            breathingMotion = true
        }
    }
}

// MARK: - Rising Embers Canvas

private struct Ember {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: CGFloat
    var opacity: Double
    var xOffset: CGFloat
}

private struct EmbersParticleCanvas: View {
    let width: CGFloat
    let height: CGFloat

    @State private var embers: [Ember] = (0..<18).map { _ in
        Ember(
            x: CGFloat.random(in: 0.15...0.85),
            y: CGFloat.random(in: 0.2...1.0),
            size: CGFloat.random(in: 2...5),
            speed: CGFloat.random(in: 0.003...0.008),
            opacity: Double.random(in: 0.4...0.9),
            xOffset: CGFloat.random(in: -0.05...0.05)
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for ember in embers {
                    let progress = (ember.y - CGFloat(now.truncatingRemainder(dividingBy: 2.0)) * ember.speed * 60)
                        .truncatingRemainder(dividingBy: 1.0)
                    let currentY = (progress < 0 ? progress + 1.0 : progress) * size.height
                    let wobble = sin(now * 3 + Double(ember.x * 10)) * 6.0
                    let currentX = (ember.x * size.width) + CGFloat(wobble)

                    let alpha = Double(currentY / size.height) * ember.opacity

                    let rect = CGRect(
                        x: currentX - ember.size / 2,
                        y: currentY - ember.size / 2,
                        width: ember.size,
                        height: ember.size
                    )

                    context.opacity = alpha
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(ember.size > 3.5 ? DoTheme.Color.gold : DoTheme.Color.comb)
                    )
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        DoTheme.Color.bg.ignoresSafeArea()
        DeathEmblemView()
    }
}
