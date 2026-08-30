import SwiftData
import SwiftUI

@main
struct DoOrDieApp: App {
    init() {
        PurchaseManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(DoTheme.Color.comb)
        }
        .modelContainer(SharedStore.makeContainer())
    }
}
