import SwiftData
import SwiftUI
import WidgetKit

/// Sits between RootView and the main app: evaluates whether the active
/// plan has died or completed and shows the right interstitial before
/// MainTabView is ever reached. The plan is only marked inactive when the
/// user taps through the interstitial — not the instant failure is
/// detected — so the screen actually gets a chance to render.
struct PlanGateView: View {
    let plan: CommitmentPlan

    @Environment(\.modelContext) private var modelContext
    @Query private var routineDays: [RoutineDay]
    @Query private var checkIns: [CheckIn]

    private var routine: [Weekday: MuscleGroup] {
        Dictionary(uniqueKeysWithValues: routineDays.map { ($0.weekday, $0.focus) })
    }

    var body: some View {
        if routineDays.count < 7 {
            RoutineSetupView(plan: plan)
        } else {
            outcomeView
        }
    }

    @ViewBuilder
    private var outcomeView: some View {
        switch PlanLifecycle.evaluate(plan: plan, routine: routine, checkIns: checkIns) {
        case .active:
            MainTabView(plan: plan)
        case .failed(let diedOnDay):
            DeathView(plan: plan, diedOnDay: diedOnDay) {
                plan.diedOnDay = diedOnDay
                plan.status = .failed
                plan.isActive = false
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        case .completed:
            PlanCompleteView(plan: plan) {
                plan.status = .completed
                plan.isActive = false
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
