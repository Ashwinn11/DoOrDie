import SwiftData
import SwiftUI
import WidgetKit

struct ProfileView: View {
    let plan: CommitmentPlan

    @Environment(\.modelContext) private var modelContext
    @Query private var routineDays: [RoutineDay]
    @Query private var checkIns: [CheckIn]

    @State private var showChangePlan = false
    @State private var showSubscription = false
    @State private var showEditWeek = false
    @State private var showDeleteConfirm = false
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false

    private var sortedDays: [RoutineDay] {
        routineDays.sorted { $0.weekdayRaw < $1.weekdayRaw }
    }

    /// Guaranteed `.active` — Profile only renders once PlanGateView has
    /// already confirmed the plan hasn't died or completed.
    private var currentDayNumber: Int {
        let routine = Dictionary(uniqueKeysWithValues: routineDays.map { ($0.weekday, $0.focus) })
        if case .active(let day) = PlanLifecycle.evaluate(plan: plan, routine: routine, checkIns: checkIns) {
            return day
        }
        return 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DoTheme.Space.lg) {
                    PlanSummaryCard(plan: plan, dayNumber: currentDayNumber) { showChangePlan = true }

                    VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                        SectionLabel("Your Week")
                        WeekOverviewCard(days: sortedDays) { showEditWeek = true }
                    }

                    VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                        SectionLabel("Account")
                        ShellCard(padding: 0) {
                            VStack(spacing: 0) {
                                Button { showSubscription = true } label: {
                                    SettingsRow(icon: "creditcard.fill", title: "Manage Subscription")
                                }
                                Divider().padding(.leading, DoTheme.Space.md)

                                NavigationLink { LegalView(kind: .terms) } label: {
                                    SettingsRow(icon: "doc.text.fill", title: "Terms of Service", showChevron: true)
                                }
                                Divider().padding(.leading, DoTheme.Space.md)

                                NavigationLink { LegalView(kind: .privacy) } label: {
                                    SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", showChevron: true)
                                }
                                Divider().padding(.leading, DoTheme.Space.md)

                                NavigationLink { CreditsView() } label: {
                                    SettingsRow(icon: "sparkles", title: "Credits", showChevron: true)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete All Data")
                                .font(DoTheme.Typography.body(16, weight: .semibold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DoTheme.Space.md)
                                .background(DoTheme.Color.shell, in: RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog(
                            "Delete everything?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("Delete All Data", role: .destructive) { deleteEverything() }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This deletes your plan, routine, and streak. This can't be undone.")
                        }

                        Text("Deletes your plan, routine, and streak history. This can't be undone.")
                            .font(DoTheme.Typography.body(13))
                            .foregroundStyle(DoTheme.Color.muted)
                            .padding(.horizontal, DoTheme.Space.xs)
                    }

                    #if DEBUG
                    debugSection
                    #endif
                }
                .padding(DoTheme.Space.md)
            }
            .background(DoTheme.Color.bg.ignoresSafeArea())
            .navigationTitle("Profile")
            .sheet(isPresented: $showChangePlan) {
                ChangePlanSheet(currentPlan: plan)
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionSheet(plan: plan)
            }
            .sheet(isPresented: $showEditWeek) {
                EditWeekSheet(routineDays: sortedDays)
            }
        }
    }

    private func deleteEverything() {
        // Fetch fresh from the context rather than relying on the view's
        // @Query snapshots — this is a destructive, one-shot operation, so
        // it should act on exactly what's on disk right now, not whatever
        // SwiftUI last cached for the view.
        if let plans = try? modelContext.fetch(FetchDescriptor<CommitmentPlan>()) {
            for p in plans { modelContext.delete(p) }
        }
        if let days = try? modelContext.fetch(FetchDescriptor<RoutineDay>()) {
            for d in days { modelContext.delete(d) }
        }
        if let checkIns = try? modelContext.fetch(FetchDescriptor<CheckIn>()) {
            for c in checkIns { modelContext.delete(c) }
        }
        hasSeenIntro = false
        do {
            try modelContext.save()
        } catch {
            // A silently-swallowed save failure here would leave the on-disk
            // store (and therefore the widget, which reads it directly)
            // untouched while the app's in-memory state looks wiped —
            // exactly the "app resets, widget doesn't" symptom to rule out.
            assertionFailure("DoOrDie: delete-all save failed: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Debug helpers (DEBUG builds only)

    #if DEBUG
    @State private var previewDeathScreen = false
    @State private var previewCompleteScreen = false
    @State private var previewOnboarding = false

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
            Text("TESTING & PREVIEWS")
                .font(DoTheme.Typography.body(12, weight: .bold))
                .foregroundStyle(.purple.opacity(0.8))
                .tracking(1)
                .padding(.leading, DoTheme.Space.xs)

            ShellCard(padding: 0) {
                VStack(spacing: 0) {
                    Button {
                        previewDeathScreen = true
                    } label: {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(DoTheme.Color.comb)
                                .frame(width: 24)
                            Text("Preview Death Screen (UI only)")
                                .font(DoTheme.Typography.body(16))
                                .foregroundStyle(DoTheme.Color.ink)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 13))
                                .foregroundStyle(DoTheme.Color.muted)
                        }
                        .padding(DoTheme.Space.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, DoTheme.Space.md)

                    Button {
                        previewCompleteScreen = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(DoTheme.Color.gold)
                                .frame(width: 24)
                            Text("Preview Complete Screen (UI only)")
                                .font(DoTheme.Typography.body(16))
                                .foregroundStyle(DoTheme.Color.ink)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 13))
                                .foregroundStyle(DoTheme.Color.muted)
                        }
                        .padding(DoTheme.Space.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, DoTheme.Space.md)

                    Button {
                        simulateSixDaysDone()
                    } label: {
                        HStack {
                            Image(systemName: "flame.circle.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Simulate 6 Days Done (Today Pending)")
                                    .font(DoTheme.Typography.body(16))
                                    .foregroundStyle(DoTheme.Color.ink)
                                Text("Sets 6 past days complete, streak=6, today pending")
                                    .font(DoTheme.Typography.body(12))
                                    .foregroundStyle(DoTheme.Color.muted)
                            }
                            Spacer()
                        }
                        .padding(DoTheme.Space.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, DoTheme.Space.md)

                    Button {
                        simulateMiss()
                    } label: {
                        HStack {
                            Image(systemName: "bolt.slash.fill")
                                .foregroundStyle(.red)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Simulate Real Miss (Trigger Gate)")
                                    .font(DoTheme.Typography.body(16))
                                    .foregroundStyle(DoTheme.Color.ink)
                                Text("Backdates plan and misses a scheduled workout day")
                                    .font(DoTheme.Typography.body(12))
                                    .foregroundStyle(DoTheme.Color.muted)
                            }
                            Spacer()
                        }
                        .padding(DoTheme.Space.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, DoTheme.Space.md)

                    Button {
                        simulateComplete()
                    } label: {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Simulate Real Complete (Trigger Gate)")
                                    .font(DoTheme.Typography.body(16))
                                    .foregroundStyle(DoTheme.Color.ink)
                                Text("Marks all days through day \(plan.durationDays) complete")
                                    .font(DoTheme.Typography.body(12))
                                    .foregroundStyle(DoTheme.Color.muted)
                            }
                            Spacer()
                        }
                        .padding(DoTheme.Space.md)
                        .contentShape(Rectangle())
                    }
                    Divider().padding(.leading, DoTheme.Space.md)

                    Button {
                        previewOnboarding = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(DoTheme.Color.comb)
                                .frame(width: 24)
                            Text("Preview Full Onboarding Flow")
                                .font(DoTheme.Typography.body(16))
                                .foregroundStyle(DoTheme.Color.ink)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 13))
                                .foregroundStyle(DoTheme.Color.muted)
                        }
                        .padding(DoTheme.Space.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .fullScreenCover(isPresented: $previewDeathScreen) {
                DeathView(plan: plan, diedOnDay: max(currentDayNumber, 7)) {
                    previewDeathScreen = false
                }
            }
            .fullScreenCover(isPresented: $previewCompleteScreen) {
                PlanCompleteView(plan: plan) {
                    previewCompleteScreen = false
                }
            }
            .fullScreenCover(isPresented: $previewOnboarding) {
                OnboardingFlowView {
                    previewOnboarding = false
                }
            }

            Text("Debug only — not visible in release builds.")
                .font(DoTheme.Typography.body(12))
                .foregroundStyle(.purple.opacity(0.5))
                .padding(.horizontal, DoTheme.Space.xs)
        }
    }

    /// Backdates the plan's startDate by 6 days and fills in check-ins for the
    /// past 6 days so streak is 6, day is 7, and today is pending.
    private func simulateSixDaysDone() {
        let cal = Calendar.current
        let routine = Dictionary(uniqueKeysWithValues: routineDays.map { ($0.weekday, $0.focus) })

        // Clear existing check-ins
        if let all = try? modelContext.fetch(FetchDescriptor<CheckIn>()) {
            for c in all { modelContext.delete(c) }
        }

        // Backdate to 6 days ago (today becomes Day 7)
        let newStart = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: .now))!
        plan.startDate = newStart

        // Fill in check-ins for the 6 previous days (exclude today so today stays pending)
        for offset in 0..<6 {
            guard let day = cal.date(byAdding: .day, value: offset, to: newStart) else { continue }
            let weekday = Weekday(rawValue: cal.component(.weekday, from: day)) ?? .sunday
            let focus = routine[weekday] ?? .chest
            if focus.demandsCheckIn {
                modelContext.insert(CheckIn(date: day, focus: focus))
            }
        }

        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Backdates the plan's startDate so today is the final day, and inserts
    /// a CheckIn for every workout day in that window — causing PlanGateView
    /// to evaluate as .completed the next time it renders.
    private func simulateComplete() {
        let cal = Calendar.current
        let routine = Dictionary(uniqueKeysWithValues: routineDays.map { ($0.weekday, $0.focus) })

        // Clear existing check-ins
        if let all = try? modelContext.fetch(FetchDescriptor<CheckIn>()) {
            for c in all { modelContext.delete(c) }
        }

        // Move startDate back so today is the last day
        let newStart = cal.date(byAdding: .day, value: -(plan.durationDays - 1), to: cal.startOfDay(for: .now))!
        plan.startDate = newStart

        // Insert a CheckIn for every workout day in the plan window up to and including today
        for offset in 0..<plan.durationDays {
            guard let day = cal.date(byAdding: .day, value: offset, to: newStart) else { continue }
            let weekday = Weekday(rawValue: cal.component(.weekday, from: day)) ?? .sunday
            let focus = routine[weekday] ?? .chest // fallback to workout if unassigned
            if focus.demandsCheckIn {
                modelContext.insert(CheckIn(date: day, focus: focus))
            }
        }

        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Backdates the plan and guarantees finding a prior day whose focus is a workout,
    /// leaving that workout uncompleted so PlanLifecycle evaluate detects a missed day.
    private func simulateMiss() {
        let cal = Calendar.current
        var routine = Dictionary(uniqueKeysWithValues: routineDays.map { ($0.weekday, $0.focus) })

        // Ensure at least one weekday is a demanding workout day
        let hasDemanding = routine.values.contains { $0.demandsCheckIn }
        if !hasDemanding {
            routine[.monday] = .chest
            routine[.tuesday] = .back
            routine[.wednesday] = .legs
            routine[.thursday] = .shoulders
            routine[.friday] = .arms
        }

        // Clear existing check-ins
        if let all = try? modelContext.fetch(FetchDescriptor<CheckIn>()) {
            for c in all { modelContext.delete(c) }
        }

        // Find the most recent day in the past (1 to 7 days ago) that was a scheduled workout day
        var missedOffset = 1
        for d in 1...7 {
            if let targetDate = cal.date(byAdding: .day, value: -d, to: cal.startOfDay(for: .now)) {
                let weekday = Weekday(rawValue: cal.component(.weekday, from: targetDate)) ?? .sunday
                let focus = routine[weekday] ?? .rest
                if focus.demandsCheckIn {
                    missedOffset = d
                    break
                }
            }
        }

        // Set start date 3 days before the missed day so streak was underway
        let missedDayDate = cal.date(byAdding: .day, value: -missedOffset, to: cal.startOfDay(for: .now))!
        let newStart = cal.date(byAdding: .day, value: -3, to: missedDayDate)!
        plan.startDate = newStart

        // Fill in check-ins for days before the missed day
        var cur = newStart
        while cur < missedDayDate {
            let weekday = Weekday(rawValue: cal.component(.weekday, from: cur)) ?? .sunday
            let focus = routine[weekday] ?? .rest
            if focus.demandsCheckIn {
                modelContext.insert(CheckIn(date: cur, focus: focus))
            }
            cur = cal.date(byAdding: .day, value: 1, to: cur) ?? cur
        }

        // Do NOT insert a check-in for missedDayDate!
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
    #endif
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(DoTheme.Typography.body(12, weight: .bold))
            .foregroundStyle(DoTheme.Color.muted)
            .tracking(1)
            .padding(.leading, DoTheme.Space.xs)
    }
}

private struct PlanSummaryCard: View {
    let plan: CommitmentPlan
    let dayNumber: Int
    let onChangePlan: () -> Void

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: DoTheme.Space.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENT PLAN")
                            .font(DoTheme.Typography.body(12, weight: .bold))
                            .foregroundStyle(DoTheme.Color.mutedOnDark)
                            .tracking(1.5)
                        Text(plan.name)
                            .font(DoTheme.Typography.title)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(PurchaseManager.shared.localizedPrice(forPlanName: plan.name))
                        .font(DoTheme.Typography.display(22, weight: .bold))
                        .foregroundStyle(DoTheme.Color.gold)
                }

                Text("Day \(dayNumber) of \(plan.durationDays)")
                    .font(DoTheme.Typography.body(14, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.mutedOnDark)

                PillButton(title: "Change Plan", style: .gold, action: onChangePlan)
            }
        }
    }
}

private struct WeekOverviewCard: View {
    let days: [RoutineDay]
    let onEdit: () -> Void

    var body: some View {
        ShellCard {
            VStack(spacing: DoTheme.Space.sm) {
                HStack(spacing: DoTheme.Space.xs) {
                    ForEach(days) { day in
                        VStack(spacing: 6) {
                            Text(day.weekday.short.prefix(1))
                                .font(DoTheme.Typography.body(11, weight: .bold))
                                .foregroundStyle(DoTheme.Color.muted)

                            ZStack {
                                RoundedRectangle(cornerRadius: DoTheme.Radius.compact, style: .continuous)
                                    .fill(day.focus == .rest ? DoTheme.Color.pillGray : DoTheme.Color.comb)
                                Image(systemName: day.focus.systemImage)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(day.focus == .rest ? DoTheme.Color.muted : DoTheme.Color.onDark)
                            }
                            .frame(width: 34, height: 34)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                PillButton(title: "Edit Week", style: .comb, action: onEdit)
            }
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: DoTheme.Space.sm) {
            Image(systemName: icon)
                .foregroundStyle(DoTheme.Color.comb)
                .frame(width: 24)
            Text(title)
                .font(DoTheme.Typography.body(16))
                .foregroundStyle(DoTheme.Color.ink)
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.muted)
            }
        }
        .padding(DoTheme.Space.md)
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileView(plan: CommitmentPlan(name: "Committed", durationDays: 60, stakeCents: 2500))
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
