import SwiftUI

/// Shown the instant a miss is detected. The stake is gone and the plan
/// is over — this is not a "keep going" screen, it's a full stop.
struct DeathView: View {
    let plan: CommitmentPlan
    let diedOnDay: Int
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: DoTheme.Space.lg) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(DoTheme.Color.comb)
                .frame(width: 84, height: 84)
                .background(DoTheme.Color.gameInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(spacing: DoTheme.Space.xs) {
                Text("YOU DIED")
                    .font(DoTheme.Typography.hero)
                    .displayTracking(48)
                    .foregroundStyle(DoTheme.Color.ink)

                Text("Missed day \(diedOnDay) of \(plan.durationDays) on \(plan.name).")
                    .font(DoTheme.Typography.body(16))
                    .foregroundStyle(DoTheme.Color.muted)
                    .multilineTextAlignment(.center)

                if plan.stakeCents > 0 {
                    Text("Your \(plan.stakeDisplay) stake is gone.")
                        .font(DoTheme.Typography.body(15, weight: .semibold))
                        .foregroundStyle(DoTheme.Color.comb)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, DoTheme.Space.lg)

            Spacer()
            Spacer()

            PillButton(title: "Buy a new plan", style: .comb, action: onContinue)
                .padding(.bottom, DoTheme.Space.sm)
        }
        .padding(DoTheme.Space.md)
        .background(DoTheme.Color.bg.ignoresSafeArea())
    }
}

#Preview {
    DeathView(plan: CommitmentPlan(name: "Ironclad", durationDays: 90, stakeCents: 4000), diedOnDay: 42) {}
}
