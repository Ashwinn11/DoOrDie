import Foundation

enum PlanOutcome: Equatable {
    case active(dayNumber: Int)
    case completed
    case failed(diedOnDay: Int)
}

/// The single source of truth for "day X of Y" and the die-on-miss rule.
/// `dayNumber` means "which day of the plan today is" — it's 1 on day one
/// whether or not you've checked in yet, same as a calendar date doesn't
/// wait for you. It is NOT the same as a streak (days actually completed);
/// see `currentStreak` below for that.
enum PlanLifecycle {
    static func evaluate(
        plan: CommitmentPlan,
        routine: [Weekday: MuscleGroup],
        checkIns: [CheckIn],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> PlanOutcome {
        let checkedDates = Set(checkIns.map { calendar.startOfDay(for: $0.date) })
        let todayStart = calendar.startOfDay(for: today)
        var cursor = calendar.startOfDay(for: plan.startDate)
        var dayNumber = 1

        while true {
            let isToday = cursor == todayStart
            let weekday = Weekday(rawValue: calendar.component(.weekday, from: cursor)) ?? .sunday
            let focus = routine[weekday] ?? .rest
            let done = !focus.demandsCheckIn || checkedDates.contains(cursor)

            if !done && !isToday {
                return .failed(diedOnDay: dayNumber)
            }

            if dayNumber >= plan.durationDays {
                return done ? .completed : .active(dayNumber: dayNumber)
            }

            if isToday {
                return .active(dayNumber: dayNumber)
            }

            dayNumber += 1
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                return .active(dayNumber: dayNumber)
            }
            cursor = next
        }
    }

    /// Days actually completed, for display as "current streak". Equal to
    /// `dayNumber` once today is done (checked in, or a rest day); one less
    /// while today is still pending, since it hasn't been survived yet.
    static func currentStreak(
        plan: CommitmentPlan,
        routine: [Weekday: MuscleGroup],
        checkIns: [CheckIn],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard case .active(let dayNumber) = evaluate(plan: plan, routine: routine, checkIns: checkIns, today: today, calendar: calendar) else {
            return 0
        }
        let todayStart = calendar.startOfDay(for: today)
        let weekday = Weekday(rawValue: calendar.component(.weekday, from: todayStart)) ?? .sunday
        let focus = routine[weekday] ?? .rest
        let checkedToday = checkIns.contains { calendar.isDate($0.date, inSameDayAs: todayStart) }
        let todayDone = !focus.demandsCheckIn || checkedToday
        return todayDone ? dayNumber : max(dayNumber - 1, 0)
    }
}
