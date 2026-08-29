import Foundation
import SwiftData

/// The stake/duration a user commits to. `stakeCents` is display-only for
/// now — no payment processor is wired up until that mechanic is finalized.
@Model
final class CommitmentPlan {
    var name: String
    var durationDays: Int
    var stakeCents: Int
    var startDate: Date
    var isActive: Bool

    init(name: String, durationDays: Int, stakeCents: Int, startDate: Date = .now, isActive: Bool = true) {
        self.name = name
        self.durationDays = durationDays
        self.stakeCents = stakeCents
        self.startDate = startDate
        self.isActive = isActive
    }

    var stakeDisplay: String {
        stakeCents == 0 ? "Free" : "$\(stakeCents / 100)"
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
    }

    var dayNumber: Int {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: .now)).day ?? 0
        return min(max(days + 1, 1), durationDays)
    }
}

enum PlanCatalog {
    static let starter = PlanTemplate(name: "Starter", durationDays: 7, stakeCents: 0, tagline: "Try the streak, no stakes")
    static let focused = PlanTemplate(name: "Focused", durationDays: 30, stakeCents: 1500, tagline: "One month, no excuses")
    static let committed = PlanTemplate(name: "Committed", durationDays: 60, stakeCents: 2500, tagline: "Miss a day, lose the pot")
    static let ironclad = PlanTemplate(name: "Ironclad", durationDays: 90, stakeCents: 4000, tagline: "The highest stakes, the deepest streak")
    static let relentless = PlanTemplate(name: "Relentless", durationDays: 180, stakeCents: 6500, tagline: "Half a year of do or die")
    static let unbreakable = PlanTemplate(name: "Unbreakable", durationDays: 365, stakeCents: 10000, tagline: "A full year. Nowhere to hide")

    static let all = [starter, focused, committed, ironclad, relentless, unbreakable]
}

struct PlanTemplate: Identifiable {
    var id: String { name }
    let name: String
    let durationDays: Int
    let stakeCents: Int
    let tagline: String

    var stakeDisplay: String {
        stakeCents == 0 ? "Free" : "$\(stakeCents / 100)"
    }
}
