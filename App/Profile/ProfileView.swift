import SwiftData
import SwiftUI

struct ProfileView: View {
    let plan: CommitmentPlan

    @Environment(\.modelContext) private var modelContext
    @Query private var routineDays: [RoutineDay]
    @Query private var allPlans: [CommitmentPlan]

    @State private var showChangePlan = false
    @State private var showSubscription = false
    @State private var showEditWeek = false
    @State private var showDeleteConfirm = false
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false

    private var sortedDays: [RoutineDay] {
        routineDays.sorted { $0.weekdayRaw < $1.weekdayRaw }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DoTheme.Space.lg) {
                    PlanSummaryCard(plan: plan) { showChangePlan = true }

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
                                .background(DoTheme.Color.shell, in: RoundedRectangle(cornerRadius: DoTheme.Radius.button, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Text("Deletes your plan, routine, and streak history. This can't be undone.")
                            .font(DoTheme.Typography.body(13))
                            .foregroundStyle(DoTheme.Color.muted)
                            .padding(.horizontal, DoTheme.Space.xs)
                    }
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
        }
    }

    private func deleteEverything() {
        for p in allPlans { modelContext.delete(p) }
        for d in routineDays { modelContext.delete(d) }
        let descriptor = FetchDescriptor<CheckIn>()
        if let checkIns = try? modelContext.fetch(descriptor) {
            for c in checkIns { modelContext.delete(c) }
        }
        hasSeenIntro = false
    }
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
                    Text(plan.stakeDisplay)
                        .font(DoTheme.Typography.display(22, weight: .bold))
                        .foregroundStyle(DoTheme.Color.gold)
                }

                Text("Day \(plan.dayNumber) of \(plan.durationDays)")
                    .font(DoTheme.Typography.body(14, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.mutedOnDark)

                PillButton(title: "Change Plan", style: .shell, action: onChangePlan)
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
                                Circle().fill(day.focus == .rest ? DoTheme.Color.pillGray : DoTheme.Color.comb)
                                Image(systemName: day.focus.systemImage)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(day.focus == .rest ? DoTheme.Color.muted : .white)
                            }
                            .frame(width: 34, height: 34)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                PillButton(title: "Edit Week", style: .ink, action: onEdit)
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
