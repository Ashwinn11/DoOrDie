import SwiftUI

/// Shown the instant a miss is detected. The stake is gone and the plan
/// is over — this is not a "keep going" screen, it's a full stop.
struct DeathView: View {
    let plan: CommitmentPlan
    let diedOnDay: Int
    let onContinue: () -> Void

    @State private var titleShake: CGFloat = 0
    @State private var flamePulse = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: DoTheme.Space.lg) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(DoTheme.Color.comb)
                .frame(width: 84, height: 84)
                .background(DoTheme.Color.gameInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .scaleEffect(flamePulse ? 1.15 : 1.0)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: flamePulse
                )
                .scaleEffect(appeared ? 1 : 0.6)
                .animation(.spring(response: 0.5, dampingFraction: 0.55), value: appeared)

            VStack(spacing: DoTheme.Space.xs) {
                Text("YOU DIED")
                    .font(DoTheme.Typography.hero)
                    .displayTracking(48)
                    .foregroundStyle(DoTheme.Color.ink)
                    .offset(x: titleShake)

                Text("Missed day \(diedOnDay) of \(plan.durationDays) on \(plan.name).")
                    .font(DoTheme.Typography.body(16))
                    .foregroundStyle(DoTheme.Color.muted)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .animation(DoTheme.Motion.easeOut.delay(0.3), value: appeared)

                if plan.stakeCents > 0 {
                    Text("Your \(plan.stakeDisplay) stake is gone.")
                        .font(DoTheme.Typography.body(15, weight: .semibold))
                        .foregroundStyle(DoTheme.Color.comb)
                        .padding(.top, 2)
                        .opacity(appeared ? 1 : 0)
                        .animation(DoTheme.Motion.easeOut.delay(0.4), value: appeared)
                }
            }
            .padding(.horizontal, DoTheme.Space.lg)

            Spacer()
            Spacer()

            PillButton(title: "Buy a new plan", style: .comb, action: onContinue)
                .padding(.bottom, DoTheme.Space.sm)
                .opacity(appeared ? 1 : 0)
                .animation(DoTheme.Motion.easeOut.delay(0.5), value: appeared)
        }
        .padding(DoTheme.Space.md)
        .background(DoTheme.Color.bg.ignoresSafeArea())
        .onAppear {
            // Error haptic fires immediately
            HapticEngine.notification(.error)

            // Elements fade in
            appeared = true

            // Flame starts pulsing
            flamePulse = true

            // Title shake: 3 quick oscillations, starts after a short settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.interpolatingSpring(stiffness: 600, damping: 8)) {
                    titleShake = -12
                }
                withAnimation(.interpolatingSpring(stiffness: 600, damping: 8).delay(0.1)) {
                    titleShake = 12
                }
                withAnimation(.interpolatingSpring(stiffness: 600, damping: 8).delay(0.2)) {
                    titleShake = -8
                }
                withAnimation(.interpolatingSpring(stiffness: 600, damping: 10).delay(0.3)) {
                    titleShake = 0
                }
            }
        }
    }
}

#Preview {
    DeathView(plan: CommitmentPlan(name: "Ironclad", durationDays: 90, stakeCents: 4000), diedOnDay: 42) {}
}
