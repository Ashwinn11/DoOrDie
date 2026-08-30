import SwiftUI

struct SubscriptionSheet: View {
    let plan: CommitmentPlan
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false
    @State private var restoreMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                DoTheme.Color.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DoTheme.Space.md) {
                        DarkCard {
                            VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                                Text("ACTIVE COMMITMENT")
                                    .font(DoTheme.Typography.body(12, weight: .bold))
                                    .foregroundStyle(DoTheme.Color.mutedOnDark)
                                    .tracking(1.5)
                                Text(plan.name)
                                    .font(DoTheme.Typography.title)
                                    .foregroundStyle(.white)
                                Text("\(PurchaseManager.shared.localizedPrice(forPlanName: plan.name)) stake · \(plan.durationDays) days")
                                    .font(DoTheme.Typography.body(14, weight: .semibold))
                                    .foregroundStyle(DoTheme.Color.gold)
                            }
                        }

                        ShellCard {
                            VStack(alignment: .leading, spacing: DoTheme.Space.xs) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(DoTheme.Color.comb)
                                    Text("Accountability & Stakes")
                                        .font(DoTheme.Typography.body(14, weight: .bold))
                                        .foregroundStyle(DoTheme.Color.ink)
                                }
                                Text("Each commitment tier is unlocked with a one-time lifetime stake. If you miss a scheduled session, your streak is forfeited.")
                                    .font(DoTheme.Typography.body(13))
                                    .foregroundStyle(DoTheme.Color.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // Restore Purchases Button (Red)
                        PillButton(title: isRestoring ? "Restoring..." : "Restore Purchases", style: .comb) {
                            restore()
                        }
                        .disabled(isRestoring)

                        if let msg = restoreMessage {
                            Text(msg)
                                .font(DoTheme.Typography.body(12))
                                .foregroundStyle(DoTheme.Color.muted)
                        }
                    }
                    .padding(DoTheme.Space.md)
                }
            }
            .navigationTitle("Membership & Stakes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func restore() {
        isRestoring = true
        restoreMessage = nil
        Task {
            do {
                let success = try await PurchaseManager.shared.restorePurchases()
                isRestoring = false
                restoreMessage = success ? "Purchases successfully restored!" : "No active purchases found to restore."
            } catch {
                isRestoring = false
                restoreMessage = "Restore failed: \(error.localizedDescription)"
            }
        }
    }
}
