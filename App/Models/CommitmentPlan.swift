import Foundation
import SwiftData

enum PlanStatus: String, Codable {
    case active, completed, failed
}

/// The stake/duration a user commits to. `stakeCents` is display-only for
/// now — no payment processor is wired up until that mechanic is finalized.
///
/// A miss kills the attempt outright: the plan's stake is forfeited and
/// `status` flips to `.failed` (see PlanLifecycle.evaluate). There is no
/// "retry within the same purchase" — a new attempt means buying again,
/// which creates a brand new CommitmentPlan with a fresh startDate.
@Model
final class CommitmentPlan {
    var name: String
    var durationDays: Int
    var stakeCents: Int
    var startDate: Date
    var isActive: Bool
    var statusRaw: String = PlanStatus.active.rawValue
    var diedOnDay: Int?

    init(name: String, durationDays: Int, stakeCents: Int, startDate: Date = .now, isActive: Bool = true) {
        self.name = name
        self.durationDays = durationDays
        self.stakeCents = stakeCents
        self.startDate = startDate
        self.isActive = isActive
        self.statusRaw = PlanStatus.active.rawValue
        self.diedOnDay = nil
    }

    var status: PlanStatus {
        get { PlanStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var stakeDisplay: String {
        stakeCents == 0 ? "Free" : "$\(stakeCents / 100)"
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
