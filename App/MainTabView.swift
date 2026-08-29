import SwiftUI
import UIKit

struct MainTabView: View {
    let plan: CommitmentPlan
    @State private var selectedTab = 0

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
        TabView(selection: $selectedTab) {
            HomeView(plan: plan)
                .tabItem { Label("Home", systemImage: "flame.fill") }
                .tag(0)

            WorkoutView(plan: plan)
                .tabItem { Label("Workout", systemImage: "figure.strengthtraining.traditional") }
                .tag(1)

            ProfileView(plan: plan)
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(2)
        }
        .tint(DoTheme.Color.comb)
        .onChange(of: selectedTab) { HapticEngine.selection() }
    }
}
