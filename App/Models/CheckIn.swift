import Foundation
import SwiftData

/// One record per day the user marked their workout done.
@Model
final class CheckIn {
    var date: Date
    var focusRaw: String
    var completedAt: Date

    init(date: Date, focus: MuscleGroup, completedAt: Date = .now) {
        self.date = Calendar.current.startOfDay(for: date)
        self.focusRaw = focus.rawValue
        self.completedAt = completedAt
    }

    var focus: MuscleGroup {
        MuscleGroup(rawValue: focusRaw) ?? .rest
    }
}
