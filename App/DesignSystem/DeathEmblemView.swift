import SwiftUI

/// A clean, cardless Death illustration featuring the defeated athlete SVG
/// floating directly on the canvas with ambient coral breathing aura and rising embers.
struct DeathEmblemView: View {
    var size: CGFloat = 200

    @State private var auraPulse = false
    @State private var breathingMotion = false

    private let deathFrames = ["ex-defeat-1", "ex-defeat-2", "ex-defeat-3"]

    var body: some View {
        ZStack {
            // 1. Ambient pulsating coral glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DoTheme.Color.coral.opacity(0.25),
                            DoTheme.Color.coral.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: size * 0.95
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .scaleEffect(auraPulse ? 1.15 : 0.92)
                .opacity(auraPulse ? 1.0 : 0.7)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: auraPulse
                )

            // 2. Rising floating embers
            EmbersParticleCanvas(width: size * 1.5, height: size * 1.5)

            // 3. Cardless Floating Defeated Lifter SVG in Coral
            CyclingSVGView(frameImageNames: deathFrames, interval: 0.6)
                .foregroundStyle(DoTheme.Color.coral)
                .frame(width: size * 1.2, height: size * 1.0)
                .scaleEffect(breathingMotion ? 1.03 : 0.97)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: breathingMotion
                )
                .shadow(color: DoTheme.Color.coral.opacity(0.2), radius: 16, y: 6)
        }
        .frame(width: size * 1.8, height: size * 1.4)
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
