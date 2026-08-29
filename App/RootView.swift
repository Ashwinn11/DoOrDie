import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @Query(filter: #Predicate<CommitmentPlan> { $0.isActive }) private var activePlans: [CommitmentPlan]
    @Query private var routineDays: [RoutineDay]

    var body: some View {
        Group {
            if !hasSeenIntro && activePlans.isEmpty {
                OnboardingIntroView(onFinish: { hasSeenIntro = true })
            } else if let plan = activePlans.first {
                if routineDays.count < 7 {
                    RoutineSetupView(plan: plan)
                } else {
                    MainTabView(plan: plan)
                }
            } else {
                PlanPickerView()
            }
        }
        .animation(DoTheme.Motion.easeOut, value: activePlans.isEmpty)
        .animation(DoTheme.Motion.easeOut, value: routineDays.count)
        .animation(DoTheme.Motion.easeOut, value: hasSeenIntro)
    }
}
