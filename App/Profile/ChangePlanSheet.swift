import SwiftData
import SwiftUI
import WidgetKit

struct ChangePlanSheet: View {
    let currentPlan: CommitmentPlan

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex: Int
    @State private var showConfirm = false

    init(currentPlan: CommitmentPlan) {
        self.currentPlan = currentPlan
        let idx = PlanCatalog.all.firstIndex { $0.name == currentPlan.name } ?? 2
        _selectedIndex = State(initialValue: idx)
    }

    private var selected: PlanTemplate { PlanCatalog.all[selectedIndex] }
    private var isCurrent: Bool { selected.name == currentPlan.name }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Switching plans resets your streak and stake. Your weekly routine stays put.")
                    .font(DoTheme.Typography.body(14))
                    .foregroundStyle(DoTheme.Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DoTheme.Space.md)
                    .padding(.top, DoTheme.Space.sm)
                    .padding(.bottom, DoTheme.Space.md)

                // Reuse the same carousel
                PlanCarousel(selectedIndex: $selectedIndex)

                // Page dots
                HStack(spacing: 6) {
                    ForEach(PlanCatalog.all.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == selectedIndex ? DoTheme.Color.comb : DoTheme.Color.pillGray)
                            .frame(width: i == selectedIndex ? 20 : 6, height: 6)
                    }
                }
                .animation(DoTheme.Motion.snappy, value: selectedIndex)
                .padding(.top, DoTheme.Space.md)

                Spacer()

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
            .background(DoTheme.Color.bg.ignoresSafeArea())
            .navigationTitle("Change Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func switchPlan(to template: PlanTemplate) {
        PlanLifecycle.startPlan(template: template, in: modelContext)
        dismiss()
    }
}
