import SwiftData
import SwiftUI

@main
struct DoOrDieApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(DoTheme.Color.comb)
        }
        .modelContainer(for: [RoutineDay.self, CommitmentPlan.self, CheckIn.self])
    }
}
