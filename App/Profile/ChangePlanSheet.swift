import SwiftData
import SwiftUI

struct ChangePlanSheet: View {
    let currentPlan: CommitmentPlan

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selected: PlanTemplate
    @State private var showConfirm = false

    init(currentPlan: CommitmentPlan) {
        self.currentPlan = currentPlan
        let match = PlanCatalog.all.first { $0.name == currentPlan.name } ?? PlanCatalog.committed
        _selected = State(initialValue: match)
    }

    private var isCurrent: Bool { selected.name == currentPlan.name }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Switching plans resets your streak and stake. Your weekly routine stays put.")
                    .font(DoTheme.Typography.body(14))
                    .foregroundStyle(DoTheme.Color.muted)
                    .padding(.horizontal, DoTheme.Space.md)
                    .padding(.top, DoTheme.Space.sm)
                    .padding(.bottom, DoTheme.Space.md)

                ScrollView {
                    VStack(spacing: DoTheme.Space.sm) {
                        ForEach(PlanCatalog.all) { template in
                            PlanOptionCard(
                                plan: template,
                                isSelected: template.name == selected.name,
                                badge: template.name == currentPlan.name ? "CURRENT" : nil
                            )
                            .onTapGesture {
                                withAnimation(DoTheme.Motion.snappy) { selected = template }
                            }
                        }
                    }
                    .padding(.horizontal, DoTheme.Space.md)
                }

                PillButton(
                    title: isCurrent ? "Keep \(selected.name)" : "Switch — \(selected.stakeDisplay)",
                    style: .comb
                ) {
                    if isCurrent {
                        dismiss()
                    } else {
                        showConfirm = true
                    }
                }
                .padding(DoTheme.Space.md)
            }
            .background(DoTheme.Color.bg.ignoresSafeArea())
            .navigationTitle("Change Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Switch to \(selected.name)?",
                isPresented: $showConfirm,
                titleVisibility: .visible
            ) {
                Button("Switch Plan", role: .destructive) { switchPlan(to: selected) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This resets your current streak to zero.")
            }
        }
    }

    private func switchPlan(to template: PlanTemplate) {
        currentPlan.isActive = false
        let newPlan = CommitmentPlan(
            name: template.name,
            durationDays: template.durationDays,
            stakeCents: template.stakeCents
        )
        modelContext.insert(newPlan)
        dismiss()
    }
}
