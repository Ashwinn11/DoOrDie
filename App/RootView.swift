import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @Query(filter: #Predicate<CommitmentPlan> { $0.isActive }) private var activePlans: [CommitmentPlan]

    var body: some View {
        Group {
            if activePlans.isEmpty {
                if !hasSeenIntro {
                    OnboardingFlowView(onFinish: { hasSeenIntro = true })
                } else {
                    PlanPickerView()
                }
            } else if let plan = activePlans.first {
                PlanGateView(plan: plan)
            }
        }
        .animation(DoTheme.Motion.easeOut, value: activePlans.isEmpty)
        .animation(DoTheme.Motion.easeOut, value: hasSeenIntro)
    }
}
