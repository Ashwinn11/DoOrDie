import SwiftData
import SwiftUI

struct RoutineSetupView: View {
    let plan: CommitmentPlan

    @Environment(\.modelContext) private var modelContext
    @State private var focusByDay: [Weekday: MuscleGroup] = Dictionary(
        uniqueKeysWithValues: Weekday.allCases.map { ($0, .rest) }
    )

    private var assignedCount: Int {
        focusByDay.values.filter { $0 != .rest }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DoTheme.Space.xs) {
                Text(plan.name.uppercased())
                    .font(DoTheme.Typography.body(13, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("Build your week.")
                    .font(DoTheme.Typography.hero)
                    .displayTracking(48)
                    .foregroundStyle(DoTheme.Color.ink)

                Text("Every day needs a job. Rest days are free — everything else is a promise.")
                    .font(DoTheme.Typography.body(15))
                    .foregroundStyle(DoTheme.Color.muted)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DoTheme.Space.md)
            .padding(.top, DoTheme.Space.lg)
            .padding(.bottom, DoTheme.Space.md)

            ScrollView {
                VStack(spacing: DoTheme.Space.sm) {
                    ForEach(Weekday.allCases) { day in
                        FocusPickerRow(
                            label: day.short,
                            focus: focusByDay[day] ?? .rest,
                            onSelect: { focusByDay[day] = $0 }
                        )
                    }
                }
                .padding(.horizontal, DoTheme.Space.md)
                .padding(.bottom, DoTheme.Space.md)
            }

            VStack(spacing: DoTheme.Space.xs) {
                PillButton(title: "Lock it in — \(assignedCount) working days", style: .comb) {
                    saveRoutine()
                }
            }
            .padding(DoTheme.Space.md)
        }
        .background(DoTheme.Color.bg.ignoresSafeArea())
    }

    private func saveRoutine() {
        for (day, focus) in focusByDay {
            modelContext.insert(RoutineDay(weekday: day, focus: focus))
        }
    }
}

#Preview {
    RoutineSetupView(plan: CommitmentPlan(name: "Committed", durationDays: 60, stakeCents: 2500))
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
