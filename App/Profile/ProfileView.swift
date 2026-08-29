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
            List {
                Section {
                    PlanSummaryCard(plan: plan) { showChangePlan = true }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section("Your Week") {
                    WeekOverviewCard(days: sortedDays) { showEditWeek = true }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section("Account") {
                    Button {
                        showSubscription = true
                    } label: {
                        SettingsRow(icon: "creditcard.fill", title: "Manage Subscription")
                    }

                    NavigationLink {
                        LegalView(kind: .terms)
                    } label: {
                        SettingsRow(icon: "doc.text.fill", title: "Terms of Service")
                    }

                    NavigationLink {
                        LegalView(kind: .privacy)
                    } label: {
                        SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy")
                    }

                    NavigationLink {
                        CreditsView()
                    } label: {
                        SettingsRow(icon: "sparkles", title: "Credits")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete All Data")
                            .font(DoTheme.Typography.body(16, weight: .semibold))
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
                } footer: {
                    Text("Deletes your plan, routine, and streak history. This can't be undone.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
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
        for p in allPlans { modelContext.delete(p) }
        for d in routineDays { modelContext.delete(d) }
        let descriptor = FetchDescriptor<CheckIn>()
        if let checkIns = try? modelContext.fetch(descriptor) {
            for c in checkIns { modelContext.delete(c) }
        }
        hasSeenIntro = false
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
        .padding(.horizontal, DoTheme.Space.md)
        .padding(.top, DoTheme.Space.sm)
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

    var body: some View {
        HStack(spacing: DoTheme.Space.sm) {
            Image(systemName: icon)
                .foregroundStyle(DoTheme.Color.comb)
                .frame(width: 24)
            Text(title)
                .font(DoTheme.Typography.body(16))
                .foregroundStyle(DoTheme.Color.ink)
        }
    }
}

#Preview {
    ProfileView(plan: CommitmentPlan(name: "Committed", durationDays: 60, stakeCents: 2500))
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
