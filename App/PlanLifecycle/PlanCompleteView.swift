import SwiftUI

/// Shown when every day of the plan is done. Success still ends the plan —
/// the next step is always buying (or free-trialing) the next one.
struct PlanCompleteView: View {
    let plan: CommitmentPlan
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var confettiPieces = makeConfetti()
    @State private var titleOffset: CGFloat = 20

    var body: some View {
        ZStack {
            // Background
            DoTheme.Color.bg.ignoresSafeArea()

            // Confetti layer (behind content)
            ForEach(confettiPieces) { piece in
                ConfettiPiece(piece: piece, active: appeared)
            }

            // Main content
            VStack(spacing: DoTheme.Space.lg) {
                Spacer()

                // Animated Victory Hero Emblem
                VictoryEmblemView(size: 130)
                    .scaleEffect(appeared ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.6), value: appeared)

                VStack(spacing: DoTheme.Space.xs) {
                    Text("DONE OR DIE")
                        .font(DoTheme.Typography.hero)
                        .displayTracking(48)
                        .foregroundStyle(DoTheme.Color.ink)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: titleOffset)
                        .animation(DoTheme.Motion.easeOut.delay(0.15), value: appeared)

                    Text("All \(plan.durationDays) days of \(plan.name), complete.")
                        .font(DoTheme.Typography.body(16))
                        .foregroundStyle(DoTheme.Color.muted)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(DoTheme.Motion.easeOut.delay(0.25), value: appeared)

                    if plan.stakeCents > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(DoTheme.Color.gold)
                            Text("\(plan.stakeDisplay) STAKE SECURED")
                                .font(DoTheme.Typography.body(14, weight: .bold))
                                .foregroundStyle(DoTheme.Color.ink)
                                .tracking(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DoTheme.Color.gold, in: Capsule())
                        .padding(.top, 4)
                        .opacity(appeared ? 1 : 0)
                        .animation(DoTheme.Motion.easeOut.delay(0.35), value: appeared)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(DoTheme.Color.gold)
                            Text("100% COMMITMENT KEPT")
                                .font(DoTheme.Typography.body(14, weight: .bold))
                                .foregroundStyle(DoTheme.Color.gold)
                                .tracking(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DoTheme.Color.gameInk, in: Capsule())
                        .padding(.top, 4)
                        .opacity(appeared ? 1 : 0)
                        .animation(DoTheme.Motion.easeOut.delay(0.35), value: appeared)
                    }
                }
                .padding(.horizontal, DoTheme.Space.lg)

                Spacer()
                Spacer()

                PillButton(title: "Choose your next plan", style: .comb, action: onContinue)
                    .padding(.bottom, DoTheme.Space.sm)
                    .opacity(appeared ? 1 : 0)
                    .animation(DoTheme.Motion.easeOut.delay(0.45), value: appeared)
            }
            .padding(DoTheme.Space.md)
        }
        .onAppear {
            HapticEngine.notification(.success)
            withAnimation { appeared = true }
            withAnimation(DoTheme.Motion.easeOut.delay(0.15)) { titleOffset = 0 }
        }
    }
}

// MARK: - Confetti

private struct ConfettiPieceData: Identifiable {
    let id = UUID()
    let x: CGFloat          // 0–1 of screen width
    let color: Color
    let size: CGFloat
    let rotation: Double    // degrees
    let delay: Double
    let duration: Double
    let shape: ConfettiShape

    enum ConfettiShape { case rect, circle }
}

private func makeConfetti() -> [ConfettiPieceData] {
    let colors: [Color] = [
        DoTheme.Color.gold, DoTheme.Color.comb,
        DoTheme.Color.gold, .white,
        DoTheme.Color.gold.opacity(0.7)
    ]
    return (0..<35).map { i in
        ConfettiPieceData(
            x: CGFloat.random(in: 0.05...0.95),
            color: colors[i % colors.count],
            size: CGFloat.random(in: 6...14),
            rotation: Double.random(in: 0...360),
            delay: Double.random(in: 0...0.6),
            duration: Double.random(in: 1.0...1.8),
            shape: i % 3 == 0 ? .circle : .rect
        )
    }
}

private struct ConfettiPiece: View {
    let piece: ConfettiPieceData
    let active: Bool

    @State private var offsetY: CGFloat = -20
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        GeometryReader { geo in
            Group {
                if piece.shape == .circle {
                    Circle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size * 0.6, height: piece.size)
                }
            }
            .rotationEffect(.degrees(rotation))
            .position(x: geo.size.width * piece.x, y: offsetY)
            .opacity(opacity)
            .onAppear {
                guard active else { return }
                let screenH = geo.size.height
                withAnimation(
                    .easeOut(duration: piece.duration).delay(piece.delay)
                ) {
                    offsetY = screenH * CGFloat.random(in: 0.4...0.85)
                    opacity = 0
                    rotation = piece.rotation + Double.random(in: 180...540)
                }
                withAnimation(.easeIn(duration: 0.12).delay(piece.delay)) {
                    opacity = 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    PlanCompleteView(plan: CommitmentPlan(name: "Starter", durationDays: 7, stakeCents: 0)) {}
}
