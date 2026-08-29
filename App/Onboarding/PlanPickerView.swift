import SwiftData
import SwiftUI
import WidgetKit

struct PlanPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selected: PlanTemplate = PlanCatalog.committed

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DoTheme.Space.xs) {
                Text("DO OR DIE")
                    .font(DoTheme.Typography.body(13, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("Pick your\ncommitment.")
                    .font(DoTheme.Typography.hero)
                    .displayTracking(48)
                    .foregroundStyle(DoTheme.Color.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Miss a day, forfeit the stake, start over.")
                    .font(DoTheme.Typography.body(15))
                    .foregroundStyle(DoTheme.Color.muted)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DoTheme.Space.md)
            .padding(.top, DoTheme.Space.lg)
            .padding(.bottom, DoTheme.Space.lg)

            ScrollView {
                VStack(spacing: DoTheme.Space.sm) {
                    ForEach(PlanCatalog.all) { plan in
                        PlanOptionCard(plan: plan, isSelected: plan.id == selected.id)
                            .onTapGesture {
                                withAnimation(DoTheme.Motion.snappy) { selected = plan }
                            }
                    }
                }
                .padding(.horizontal, DoTheme.Space.md)
            }

            VStack(spacing: DoTheme.Space.xs) {
                PillButton(title: "Commit — \(selected.stakeDisplay)", style: .comb) {
                    startPlan()
                }
                Text("Stakes aren't charged yet in this build.")
                    .font(DoTheme.Typography.body(12))
                    .foregroundStyle(DoTheme.Color.muted)
            }
            .padding(DoTheme.Space.md)
        }
        .background(DoTheme.Color.bg.ignoresSafeArea())
    }

    private func startPlan() {
        let plan = CommitmentPlan(
            name: selected.name,
            durationDays: selected.durationDays,
            stakeCents: selected.stakeCents
        )
        modelContext.insert(plan)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    PlanPickerView()
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
