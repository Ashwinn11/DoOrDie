import SwiftUI
import UIKit

struct MainTabView: View {
    let plan: CommitmentPlan

    init(plan: CommitmentPlan) {
        self.plan = plan
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(DoTheme.Color.comb)
    }

    var body: some View {
        TabView {
            HomeView(plan: plan)
                .tabItem { Label("Home", systemImage: "flame.fill") }

            WorkoutView(plan: plan)
                .tabItem { Label("Workout", systemImage: "figure.strengthtraining.traditional") }

            ProfileView(plan: plan)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(DoTheme.Color.comb)
    }
}
