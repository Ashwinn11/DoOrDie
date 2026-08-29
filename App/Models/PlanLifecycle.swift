import Foundation
import SwiftData
import WidgetKit

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

    // MARK: - Centralized Lifecycle Operations

    /// Purges all check-in records strictly prior to today's start of day.
    /// Preserves today's check-in (if present) so workouts performed today aren't lost.
    static func purgeHistoryBeforeToday(in context: ModelContext) {
        let todayStart = Calendar.current.startOfDay(for: .now)
        if let all = try? context.fetch(FetchDescriptor<CheckIn>()) {
            for c in all where c.date < todayStart {
                context.delete(c)
            }
        }
    }

    /// Starts or switches to a new commitment plan:
    /// 1. Deactivates existing active plans.
    /// 2. Purges all past check-in records prior to today.
    /// 3. Creates and inserts the new active plan.
    /// 4. Saves and reloads widget timelines.
    @MainActor
    static func startPlan(
        template: PlanTemplate,
        in context: ModelContext
    ) {
        purgeHistoryBeforeToday(in: context)

        if let active = try? context.fetch(FetchDescriptor<CommitmentPlan>(predicate: #Predicate { $0.isActive })) {
            for p in active { p.isActive = false }
        }

        let newPlan = CommitmentPlan(
            name: template.name,
            durationDays: template.durationDays,
            stakeCents: template.stakeCents,
            startDate: .now,
            isActive: true
        )
        context.insert(newPlan)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Handles plan failure (user died):
    /// 1. Marks plan failed and inactive.
    /// 2. Purges all past check-ins.
    /// 3. Saves and reloads widgets.
    @MainActor
    static func handleFailure(
        plan: CommitmentPlan,
        diedOnDay: Int,
        in context: ModelContext
    ) {
        purgeHistoryBeforeToday(in: context)
        plan.diedOnDay = diedOnDay
        plan.status = .failed
        plan.isActive = false
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Handles plan completion:
    /// 1. Marks plan completed and inactive.
    /// 2. Purges all past check-ins.
    /// 3. Saves and reloads widgets.
    @MainActor
    static func handleCompletion(
        plan: CommitmentPlan,
        in context: ModelContext
    ) {
        purgeHistoryBeforeToday(in: context)
        plan.status = .completed
        plan.isActive = false
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
