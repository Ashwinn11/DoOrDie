import SwiftData
import WidgetKit

struct DayCell: Identifiable {
    let id: Int
    let focus: MuscleGroup
    let isDone: Bool
    let isToday: Bool
}

struct DoOrDieEntry: TimelineEntry {
    let date: Date
    let planName: String
    let durationDays: Int
    let stakeDisplay: String
    let outcome: PlanOutcome
    let cells: [DayCell]

    static let placeholder = DoOrDieEntry(
        date: .now,
        planName: "Committed",
        durationDays: 60,
        stakeDisplay: "$25",
        outcome: .active(dayNumber: 14),
        cells: (1...60).map { i in
            DayCell(id: i, focus: MuscleGroup.allCases[i % MuscleGroup.allCases.count], isDone: i < 14, isToday: i == 14)
        }
    )

    static let noPlan = DoOrDieEntry(
        date: .now,
        planName: "",
        durationDays: 0,
        stakeDisplay: "",
        outcome: .active(dayNumber: 0),
        cells: []
    )
}

struct DoOrDieTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoOrDieEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DoOrDieEntry) -> Void) {
        completion(context.isPreview ? .placeholder : buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoOrDieEntry>) -> Void) {
        let entry = buildEntry()
        let nextMidnight = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime) ?? Date(timeIntervalSinceNow: 3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func buildEntry() -> DoOrDieEntry {
        let container = SharedStore.makeContainer()
        let context = ModelContext(container)

        let planDescriptor = FetchDescriptor<CommitmentPlan>(predicate: #Predicate { $0.isActive })
        guard let plan = try? context.fetch(planDescriptor).first else {
            return .noPlan
        }

        let routineDays = (try? context.fetch(FetchDescriptor<RoutineDay>())) ?? []
        let checkIns = (try? context.fetch(FetchDescriptor<CheckIn>())) ?? []
        let routine = Dictionary(uniqueKeysWithValues: routineDays.map { ($0.weekday, $0.focus) })

        let outcome = PlanLifecycle.evaluate(plan: plan, routine: routine, checkIns: checkIns)
        let checkedDates = Set(checkIns.map { Calendar.current.startOfDay(for: $0.date) })
        let todayStart = Calendar.current.startOfDay(for: .now)

        var cells: [DayCell] = []
        var cursor = Calendar.current.startOfDay(for: plan.startDate)
        for i in 1...plan.durationDays {
            let weekday = Weekday(rawValue: Calendar.current.component(.weekday, from: cursor)) ?? .sunday
            let focus = routine[weekday] ?? .rest
            let isToday = cursor == todayStart
            let isDone = !focus.demandsCheckIn ? cursor < todayStart : checkedDates.contains(cursor)
            cells.append(DayCell(id: i, focus: focus, isDone: isDone, isToday: isToday))
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return DoOrDieEntry(
            date: .now,
            planName: plan.name,
            durationDays: plan.durationDays,
            stakeDisplay: plan.stakeDisplay,
            outcome: outcome,
            cells: cells
        )
    }
}
