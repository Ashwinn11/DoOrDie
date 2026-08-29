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
        // Wipe all check-ins from before today so the new plan starts
        // with a clean slate. Today's check-in (if it exists) is kept —
        // the user already did that workout; they shouldn't have to log it
        // again just because they switched plans.
        let todayStart = Calendar.current.startOfDay(for: .now)
        if let all = try? modelContext.fetch(FetchDescriptor<CheckIn>()) {
            for checkIn in all where checkIn.date < todayStart {
                modelContext.delete(checkIn)
            }
        }

        currentPlan.isActive = false
        let newPlan = CommitmentPlan(
            name: template.name,
            durationDays: template.durationDays,
            stakeCents: template.stakeCents
        )
        modelContext.insert(newPlan)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
