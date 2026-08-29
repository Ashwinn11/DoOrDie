import Foundation
import SwiftData

/// The app and the widget extension are separate processes — this is the
/// one thing both must agree on to read/write the same on-disk data.
enum SharedStore {
    static let appGroupID = "group.com.brolee.app"

    static var schema: Schema {
        Schema([RoutineDay.self, CommitmentPlan.self, CheckIn.self])
    }

    static func makeContainer() -> ModelContainer {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            // Falls back to an app-local store so previews/tests without the
            // App Group entitlement still run, instead of crashing outright.
            return (try? ModelContainer(for: schema)) ?? (try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]))
        }
        let storeURL = groupURL.appendingPathComponent("DoOrDie.sqlite")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        return (try? ModelContainer(for: schema, configurations: [config])) ?? (try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]))
    }
}
