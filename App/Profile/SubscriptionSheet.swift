import SwiftUI

/// No payment processor is wired up yet — this mirrors what the real
/// subscription screen will look like once the commitment-price mechanic
/// is finalized.
struct SubscriptionSheet: View {
    let plan: CommitmentPlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DoTheme.Space.md) {
                    DarkCard {
                        VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                            Text("ACTIVE PLAN")
                                .font(DoTheme.Typography.body(12, weight: .bold))
                                .foregroundStyle(DoTheme.Color.mutedOnDark)
                                .tracking(1.5)
                            Text(plan.name)
                                .font(DoTheme.Typography.title)
                                .foregroundStyle(.white)
                            Text("\(plan.stakeDisplay) stake · \(plan.durationDays) days")
                                .font(DoTheme.Typography.body(14, weight: .semibold))
                                .foregroundStyle(DoTheme.Color.gold)
                        }
                    }

                    VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                        Label("No charge has been made yet", systemImage: "info.circle.fill")
                            .font(DoTheme.Typography.body(14, weight: .semibold))
                            .foregroundStyle(DoTheme.Color.comb)
                        Text("Stakes aren't processed in this build — no payment method is on file, and nothing will be charged. When billing ships, you'll manage it here and in the App Store.")
                            .font(DoTheme.Typography.body(14))
                            .foregroundStyle(DoTheme.Color.muted)
                    }
                    .padding(DoTheme.Space.md)
                    .background(DoTheme.Color.shell, in: RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous))

                    PillButton(title: "Manage in App Store", style: .ink) {}
                        .disabled(true)
                        .opacity(0.4)
                }
                .padding(DoTheme.Space.md)
            }
            .background(DoTheme.Color.bg.ignoresSafeArea())
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
