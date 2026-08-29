import SwiftData

/// One entry per weekday (1...7). Editing a day just overwrites `focusRaw`.
@Model
final class RoutineDay {
    var weekdayRaw: Int
    var focusRaw: String

    init(weekday: Weekday, focus: MuscleGroup) {
        self.weekdayRaw = weekday.rawValue
        self.focusRaw = focus.rawValue
    }

    var weekday: Weekday {
        get { Weekday(rawValue: weekdayRaw) ?? .sunday }
        set { weekdayRaw = newValue.rawValue }
    }

    var focus: MuscleGroup {
        get { MuscleGroup(rawValue: focusRaw) ?? .rest }
        set { focusRaw = newValue.rawValue }
    }
}
