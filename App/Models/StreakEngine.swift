import Foundation

enum DayStatus {
    case done
    case pending
    case upcoming
}

enum StreakEngine {
    static func status(
        for date: Date,
        focus: MuscleGroup,
        checkIns: [CheckIn],
        planStartDate: Date,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> DayStatus {
        let dayStart = calendar.startOfDay(for: date)
        let todayStart = calendar.startOfDay(for: today)
        let planStart = calendar.startOfDay(for: planStartDate)

        // Days before plan started or future days are upcoming
        guard dayStart >= planStart, dayStart <= todayStart else {
            return .upcoming
        }

        let isDone = !focus.demandsCheckIn || checkIns.contains { calendar.isDate($0.date, inSameDayAs: dayStart) }
        return isDone ? .done : .pending
    }
}
