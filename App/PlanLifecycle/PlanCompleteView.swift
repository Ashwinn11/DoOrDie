import SwiftUI

/// Shown when every day of the plan is done. Success still ends the plan —
/// the next step is always buying (or free-trialing) the next one.
struct PlanCompleteView: View {
    let plan: CommitmentPlan
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: DoTheme.Space.lg) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(DoTheme.Color.gold)
                .frame(width: 84, height: 84)
                .background(DoTheme.Color.gameInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(spacing: DoTheme.Space.xs) {
                Text("DONE OR DIE")
                    .font(DoTheme.Typography.hero)
                    .displayTracking(48)
                    .foregroundStyle(DoTheme.Color.ink)

                Text("All \(plan.durationDays) days of \(plan.name), complete.")
                    .font(DoTheme.Typography.body(16))
                    .foregroundStyle(DoTheme.Color.muted)
                    .multilineTextAlignment(.center)

                Text("Ready for the next one?")
                    .font(DoTheme.Typography.body(15, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .padding(.top, 2)
            }
            .padding(.horizontal, DoTheme.Space.lg)

            Spacer()
            Spacer()

            PillButton(title: "Choose your next plan", style: .comb, action: onContinue)
                .padding(.bottom, DoTheme.Space.sm)
        }
        .padding(DoTheme.Space.md)
        .background(DoTheme.Color.bg.ignoresSafeArea())
    }
}

#Preview {
    PlanCompleteView(plan: CommitmentPlan(name: "Starter", durationDays: 7, stakeCents: 0)) {}
}
