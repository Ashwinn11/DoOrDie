import Foundation

enum DayStatus {
    case done
    case pending
    case restDay
}

enum StreakEngine {
    /// Walks backward from today. Rest days are free passes; a missed
    /// demanding day (or an as-yet-unchecked today) stops the count —
    /// that's the "streak death" mechanic.
    static func currentStreak(
        routine: [Weekday: MuscleGroup],
        checkIns: [CheckIn],
        startDate: Date,
        asOf today: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let checkedDates = Set(checkIns.map { calendar.startOfDay(for: $0.date) })
        let start = calendar.startOfDay(for: startDate)
        var streak = 0
        var cursor = calendar.startOfDay(for: today)

        while cursor >= start {
            let weekday = Weekday(rawValue: calendar.component(.weekday, from: cursor)) ?? .sunday
            let focus = routine[weekday] ?? .rest
            let isToday = calendar.isDate(cursor, inSameDayAs: today)

            if focus.demandsCheckIn {
                if checkedDates.contains(cursor) {
                    streak += 1
                } else {
                    break
                }
            }
            _ = isToday
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

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
