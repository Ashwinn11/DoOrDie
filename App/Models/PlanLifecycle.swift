import Foundation

enum PlanOutcome: Equatable {
    case active(dayNumber: Int)
    case completed
    case failed(diedOnDay: Int)
}

/// The single source of truth for "day X of Y" and the die-on-miss rule.
/// A plan has no separate streak counter — its day count IS the streak,
/// because a miss doesn't decrement anything, it ends the attempt.
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
}
