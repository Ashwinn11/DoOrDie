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
        ZStack {
            DoTheme.Color.bg.ignoresSafeArea()

            VStack(spacing: DoTheme.Space.lg) {
                Spacer()

                // Animated Death Hero Emblem
                DeathEmblemView(size: 130)
                    .scaleEffect(appeared ? 1.0 : 0.94)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(DoTheme.Motion.springDelight, value: appeared)

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
                        .animation(DoTheme.Motion.easeOut.delay(0.25), value: appeared)

                    if plan.stakeCents > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(DoTheme.Color.coral)
                            Text("\(PurchaseManager.shared.localizedPrice(forPlanName: plan.name)) STAKE FORFEITED")
                                .font(DoTheme.Typography.body(14, weight: .bold))
                                .foregroundStyle(DoTheme.Color.coral)
                                .tracking(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DoTheme.Color.coral.opacity(0.12), in: Capsule())
                        .padding(.top, DoTheme.Space.xs)
                        .opacity(appeared ? 1 : 0)
                        .animation(DoTheme.Motion.easeOut.delay(0.35), value: appeared)
                    }
                }
                .padding(.horizontal, DoTheme.Space.lg)

                Spacer()
                Spacer()

                PillButton(title: "Start a new plan", style: .coral, action: onContinue)
                    .padding(.bottom, DoTheme.Space.sm)
                    .opacity(appeared ? 1 : 0)
                    .animation(DoTheme.Motion.easeOut.delay(0.45), value: appeared)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DoTheme.Space.md)
        }
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
