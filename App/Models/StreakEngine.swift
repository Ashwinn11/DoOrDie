import Foundation

enum DayStatus {
    case done
    case pending
    case restDay
}

enum StreakEngine {
    static func status(
        for date: Date,
        focus: MuscleGroup,
        checkIns: [CheckIn],
        calendar: Calendar = .current
    ) -> DayStatus {
        guard focus.demandsCheckIn else { return .restDay }
        let day = calendar.startOfDay(for: date)
        let done = checkIns.contains { calendar.isDate($0.date, inSameDayAs: day) }
        return done ? .done : .pending
    }
}
