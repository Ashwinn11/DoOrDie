import SwiftData
import SwiftUI
import WidgetKit

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
        StreakEngine.status(for: .now, focus: todayFocus, checkIns: checkIns, planStartDate: plan.startDate)
    }

    /// Guaranteed `.active` — PlanGateView only renders HomeView for an
    /// active plan, so the day count here can never reflect a miss.
    private var dayNumber: Int {
        if case .active(let day) = PlanLifecycle.evaluate(plan: plan, routine: routine, checkIns: checkIns) {
            return day
        }
        return 1
    }

    /// Days actually completed — 0 on day one before you've checked in,
    /// unlike dayNumber which is already "1" the moment the day starts.
    private var streak: Int {
        PlanLifecycle.currentStreak(plan: plan, routine: routine, checkIns: checkIns)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DoTheme.Space.md) {
                header

                StreakHero(streak: streak, dayNumber: dayNumber, totalDays: plan.durationDays)

                TodayCard(focus: todayFocus, status: todayStatus, onCheckIn: checkInToday)

                WeekStrip(planStartDate: plan.startDate, routine: routine, checkIns: checkIns)
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
            Chip(text: "Day \(dayNumber) of \(plan.durationDays)")
        }
        .padding(.top, DoTheme.Space.sm)
    }

    private func checkInToday() {
        guard todayStatus == .pending else { return }
        modelContext.insert(CheckIn(date: .now, focus: todayFocus))
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - StreakHero

private struct StreakHero: View {
    let streak: Int
    let dayNumber: Int
    let totalDays: Int

    @State private var flamePulse = false

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
                            .contentTransition(.numericText(countsDown: false))
                            .animation(DoTheme.Motion.easeOut, value: streak)
                        Text(streak == 1 ? "day" : "days")
                            .font(DoTheme.Typography.body(16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(DoTheme.Color.gold)
                    .scaleEffect(flamePulse ? 1.08 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: flamePulse
                    )
            }
        }
        .onAppear { flamePulse = true }
    }
}

// MARK: - TodayCard

private struct TodayCard: View {
    let focus: MuscleGroup
    let status: DayStatus
    let onCheckIn: () -> Void

    @State private var particles: [Particle] = []
    @State private var showBurst = false
    @State private var chipScale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
            Text("TODAY'S COMMITMENT")
                .font(DoTheme.Typography.body(12, weight: .bold))
                .foregroundStyle(DoTheme.Color.muted)
                .tracking(1.5)
                .padding(.leading, DoTheme.Space.xs)

            ShellCard {
                VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                    HStack(spacing: DoTheme.Space.sm) {
                        Image(systemName: focus.systemImage)
                            .font(.system(size: 28))
                            .foregroundStyle(status == .done ? DoTheme.Color.ink : .white)
                            .frame(width: 48, height: 48)
                            .background(
                                status == .done ? DoTheme.Color.gold : DoTheme.Color.comb,
                                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                            )
                            .animation(DoTheme.Motion.snappy, value: status)

                        Text(focus.label)
                            .font(DoTheme.Typography.title)
                            .foregroundStyle(DoTheme.Color.ink)

                        Spacer()

                        statusChip
                            .scaleEffect(chipScale)
                    }

                    if focus.demandsCheckIn {
                        ZStack {
                            PillButton(
                                title: status == .done ? "Done for today" : "Do it",
                                systemImage: status == .done ? "flame.fill" : nil,
                                style: status == .done ? .gold : .comb,
                                action: handleCheckIn
                            )
                            .disabled(status == .done)

                            // Particle burst overlay
                            if showBurst {
                                ForEach(particles) { p in
                                    ParticleView(particle: p, active: showBurst)
                                }
                            }
                        }
                    } else {
                        Text("Rest day. The streak doesn't need you today.")
                            .font(DoTheme.Typography.body(14))
                            .foregroundStyle(DoTheme.Color.muted)
                    }
                }
            }
        }
    }

    private var statusChip: some View {
        switch status {
        case .done:
            Chip(text: "DONE", tint: DoTheme.Color.gold)
        case .pending, .upcoming:
            Chip(text: "PENDING", tint: DoTheme.Color.comb, textColor: .white)
        }
    }

    private func handleCheckIn() {
        guard status == .pending else { return }
        HapticEngine.notification(.success)
        triggerBurst()
        onCheckIn()
    }

    private func triggerBurst() {
        particles = makeParticles()
        showBurst = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { chipScale = 1.2 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { chipScale = 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            showBurst = false
            particles = []
        }
    }
}

// MARK: - Particle Burst Components

private struct Particle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let color: Color
    let delay: Double
}

private func makeParticles() -> [Particle] {
    (0..<18).map { i in
        Particle(
            angle: (Double(i) / 18.0) * 2 * .pi + Double.random(in: -0.15...0.15),
            distance: CGFloat.random(in: 32...72),
            size: CGFloat.random(in: 4...8),
            color: i % 2 == 0 ? DoTheme.Color.gold : DoTheme.Color.comb,
            delay: Double.random(in: 0...0.06)
        )
    }
}

private struct ParticleView: View {
    let particle: Particle
    let active: Bool

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let dx = cos(particle.angle) * particle.distance
                let dy = sin(particle.angle) * particle.distance
                withAnimation(.easeOut(duration: 0.55).delay(particle.delay)) {
                    offset = CGSize(width: dx, height: dy)
                    opacity = 0
                }
            }
    }
}

// MARK: - WeekStrip

private struct WeekStrip: View {
    let planStartDate: Date
    let routine: [Weekday: MuscleGroup]
    let checkIns: [CheckIn]

    var body: some View {
        VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
            Text("THIS WEEK")
                .font(DoTheme.Typography.body(12, weight: .bold))
                .foregroundStyle(DoTheme.Color.muted)
                .tracking(1.5)
                .padding(.leading, DoTheme.Space.xs)

            ShellCard {
                HStack(spacing: DoTheme.Space.xs) {
                    ForEach(Array(Weekday.allCases.enumerated()), id: \.offset) { index, day in
                        DayDot(
                            day: day,
                            focus: routine[day] ?? .rest,
                            status: StreakEngine.status(
                                for: dateFor(day),
                                focus: routine[day] ?? .rest,
                                checkIns: checkIns,
                                planStartDate: planStartDate
                            ),
                            isToday: day == .today,
                            entranceDelay: Double(index) * 0.05
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

// MARK: - DayDot

private struct DayDot: View {
    let day: Weekday
    let focus: MuscleGroup
    let status: DayStatus
    let isToday: Bool
    let entranceDelay: Double

    @State private var appeared = false

    private var fill: Color {
        switch status {
        case .done: DoTheme.Color.gold
        case .pending: isToday ? DoTheme.Color.comb : DoTheme.Color.pillGray
        case .upcoming: DoTheme.Color.pillGray
        }
    }

    private var iconColor: Color {
        switch status {
        case .done: DoTheme.Color.ink
        case .pending: isToday ? .white : DoTheme.Color.muted
        case .upcoming: DoTheme.Color.muted
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(day.short.prefix(1))
                .font(DoTheme.Typography.body(11, weight: .bold))
                .foregroundStyle(isToday ? DoTheme.Color.ink : DoTheme.Color.muted)

            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(fill)
                    .animation(DoTheme.Motion.snappy, value: status)
                Image(systemName: focus.systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(iconColor)
                    .animation(DoTheme.Motion.snappy, value: status)
            }
            .frame(width: 34, height: 34)
            .scaleEffect(appeared ? 1 : 0.6)
            .animation(
                .spring(response: 0.4, dampingFraction: isToday ? 0.5 : 0.7)
                .delay(entranceDelay),
                value: appeared
            )
        }
        .frame(maxWidth: .infinity)
        .onAppear { appeared = true }
    }
}

#Preview {
    HomeView(plan: CommitmentPlan(name: "Committed", durationDays: 60, stakeCents: 2500))
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
