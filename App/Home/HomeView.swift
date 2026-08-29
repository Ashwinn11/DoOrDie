import SwiftData
import SwiftUI

struct HomeView: View {
    let plan: CommitmentPlan

    @Environment(\.modelContext) private var modelContext
    @Query private var routineDays: [RoutineDay]
    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]

    private var routine: [Weekday: MuscleGroup] {
        Dictionary(uniqueKeysWithValues: routineDays.map { ($0.weekday, $0.focus) })
    }

    private var todayFocus: MuscleGroup {
        routine[.today] ?? .rest
    }

    private var todayStatus: DayStatus {
        StreakEngine.status(for: .now, focus: todayFocus, checkIns: checkIns)
    }

    private var streak: Int {
        StreakEngine.currentStreak(routine: routine, checkIns: checkIns, startDate: plan.startDate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DoTheme.Space.md) {
                header

                StreakHero(streak: streak, dayNumber: plan.dayNumber, totalDays: plan.durationDays)

                TodayCard(focus: todayFocus, status: todayStatus, onCheckIn: checkInToday)

                WeekStrip(routine: routine, checkIns: checkIns)
            }
            .padding(DoTheme.Space.md)
        }
        .background(DoTheme.Color.bg.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name.uppercased())
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(1.5)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(DoTheme.Typography.display(22, weight: .bold))
                    .foregroundStyle(DoTheme.Color.ink)
            }
            Spacer()
            Chip(text: "Day \(plan.dayNumber)/\(plan.durationDays)")
        }
        .padding(.top, DoTheme.Space.sm)
    }

    private func checkInToday() {
        guard todayStatus == .pending else { return }
        modelContext.insert(CheckIn(date: .now, focus: todayFocus))
    }
}

private struct StreakHero: View {
    let streak: Int
    let dayNumber: Int
    let totalDays: Int

    var body: some View {
        DarkCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT STREAK")
                        .font(DoTheme.Typography.body(12, weight: .bold))
                        .foregroundStyle(DoTheme.Color.mutedOnDark)
                        .tracking(1.5)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(streak)")
                            .font(DoTheme.Typography.streakNumber)
                            .foregroundStyle(DoTheme.Color.gold)
                        Text(streak == 1 ? "day" : "days")
                            .font(DoTheme.Typography.body(16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(DoTheme.Color.gold)
            }
        }
    }
}

private struct TodayCard: View {
    let focus: MuscleGroup
    let status: DayStatus
    let onCheckIn: () -> Void

    var body: some View {
        ShellCard {
            VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                HStack {
                    Text("TODAY'S COMMITMENT")
                        .font(DoTheme.Typography.body(12, weight: .bold))
                        .foregroundStyle(DoTheme.Color.muted)
                        .tracking(1.5)
                    Spacer()
                    statusChip
                }

                HStack(spacing: DoTheme.Space.sm) {
                    Image(systemName: focus.systemImage)
                        .font(.system(size: 28))
                        .foregroundStyle(DoTheme.Color.comb)
                        .frame(width: 48, height: 48)
                        .background(DoTheme.Color.pillGray, in: Circle())

                    Text(focus.label)
                        .font(DoTheme.Typography.title)
                        .foregroundStyle(DoTheme.Color.ink)

                    Spacer()
                }

                if focus.demandsCheckIn {
                    PillButton(
                        title: status == .done ? "Done for today" : "Do it",
                        systemImage: status == .done ? "checkmark" : nil,
                        style: status == .done ? .shell : .comb,
                        action: onCheckIn
                    )
                    .disabled(status == .done)
                } else {
                    Text("Rest day. The streak doesn't need you today.")
                        .font(DoTheme.Typography.body(14))
                        .foregroundStyle(DoTheme.Color.muted)
                }
            }
        }
    }

    private var statusChip: some View {
        switch status {
        case .done:
            Chip(text: "DONE", tint: DoTheme.Color.gold)
        case .pending:
            Chip(text: "PENDING", tint: DoTheme.Color.comb, textColor: .white)
        case .restDay:
            Chip(text: "REST", tint: DoTheme.Color.pillGray)
        }
    }
}

private struct WeekStrip: View {
    let routine: [Weekday: MuscleGroup]
    let checkIns: [CheckIn]

    var body: some View {
        ShellCard {
            VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                Text("THIS WEEK")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.muted)
                    .tracking(1.5)

                HStack(spacing: DoTheme.Space.xs) {
                    ForEach(Weekday.allCases) { day in
                        DayDot(
                            day: day,
                            focus: routine[day] ?? .rest,
                            status: StreakEngine.status(for: dateFor(day), focus: routine[day] ?? .rest, checkIns: checkIns),
                            isToday: day == .today
                        )
                    }
                }
            }
        }
    }

    private func dateFor(_ day: Weekday) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let todayWeekday = calendar.component(.weekday, from: today)
        let delta = day.rawValue - todayWeekday
        return calendar.date(byAdding: .day, value: delta, to: today) ?? today
    }
}

private struct DayDot: View {
    let day: Weekday
    let focus: MuscleGroup
    let status: DayStatus
    let isToday: Bool

    private var fill: Color {
        switch status {
        case .done: DoTheme.Color.gold
        case .pending: isToday ? DoTheme.Color.comb : DoTheme.Color.pillGray
        case .restDay: DoTheme.Color.pillGray
        }
    }

    private var iconColor: Color {
        switch status {
        case .done: DoTheme.Color.ink
        case .pending: isToday ? .white : DoTheme.Color.muted
        case .restDay: DoTheme.Color.muted
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(day.short.prefix(1))
                .font(DoTheme.Typography.body(11, weight: .bold))
                .foregroundStyle(isToday ? DoTheme.Color.ink : DoTheme.Color.muted)

            ZStack {
                Circle().fill(fill)
                if isToday {
                    Circle().strokeBorder(DoTheme.Color.ink, lineWidth: 2)
                }
                Image(systemName: status == .done ? "checkmark" : focus.systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 34, height: 34)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView(plan: CommitmentPlan(name: "Committed", durationDays: 60, stakeCents: 2500))
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
