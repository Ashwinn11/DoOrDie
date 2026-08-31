import SwiftData
import SwiftUI
import WidgetKit

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    let onFinish: () -> Void

    @State private var currentStep = 0
    private let totalSteps = 10

    // Quiz & Setup State
    @State private var pastAttempts: String? = nil
    @State private var failureReason: String? = nil
    @State private var identityReason: String? = nil
    @State private var selectedPlanIndex = 1 // Default to "Committed" (60d)
    @State private var focusByDay: [Weekday: MuscleGroup] = Dictionary(
        uniqueKeysWithValues: Weekday.allCases.map { ($0, .rest) }
    )

    private var selectedTemplate: PlanTemplate {
        PlanCatalog.all[selectedPlanIndex]
    }

    private var assignedWorkingDays: Int {
        focusByDay.values.filter { $0 != .rest }.count
    }

    var body: some View {
        ZStack {
            DoTheme.Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Progress Bar
                topBar
                    .padding(.horizontal, DoTheme.Space.md)
                    .padding(.top, DoTheme.Space.sm)

                // Step Content Container (Enforces explicit navigation - no accidental skipping)
                ZStack {
                    switch currentStep {
                    case 0:
                        Step1HookView(onNext: nextStep)
                    case 1:
                        Step2PastPatternView(selected: $pastAttempts, onNext: nextStep)
                    case 2:
                        Step3RootCauseView(selected: $failureReason, onNext: nextStep)
                    case 3:
                        Step4ScienceView(onNext: nextStep)
                    case 4:
                        Step5TheLawView(onNext: nextStep)
                    case 5:
                        Step6SplitSetupView(focusByDay: $focusByDay, onNext: nextStep)
                    case 6:
                        Step7PlanCarouselView(selectedIndex: $selectedPlanIndex, onNext: nextStep)
                    case 7:
                        Step8IdentityView(selected: $identityReason, onNext: nextStep)
                    case 8:
                        Step9ContractGenView(
                            template: selectedTemplate,
                            workingDays: assignedWorkingDays,
                            onNext: nextStep
                        )
                    case 9:
                        Step10OathView(
                            template: selectedTemplate,
                            workingDays: assignedWorkingDays,
                            onComplete: finalizeOnboarding
                        )
                    default:
                        EmptyView()
                    }
                }
                .animation(DoTheme.Motion.snappy, value: currentStep)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Top Navigation Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            if currentStep > 0 && currentStep < totalSteps - 1 {
                Button {
                    HapticEngine.impact(.light)
                    withAnimation(DoTheme.Motion.snappy) {
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DoTheme.Color.ink)
                        .frame(width: 44, height: 44)
                        .background(DoTheme.Color.shell, in: Circle())
                        .doShadow(DoTheme.Shadow.resting)
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            // Segmented Progress Bar
            GeometryReader { geo in
                let progress = CGFloat(currentStep + 1) / CGFloat(totalSteps)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.12))
                        .frame(height: 5)
                    Capsule()
                        .fill(DoTheme.Color.comb)
                        .frame(width: max(geo.size.width * progress, 12), height: 5)
                }
            }
            .frame(height: 5)
            .animation(DoTheme.Motion.snappy, value: currentStep)

            Text("\(currentStep + 1)/\(totalSteps)")
                .font(DoTheme.Typography.body(11, weight: .bold))
                .foregroundStyle(DoTheme.Color.muted)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private func nextStep() {
        HapticEngine.impact(.light)
        withAnimation(DoTheme.Motion.snappy) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    private func finalizeOnboarding() {
        HapticEngine.notification(.success)

        // 1. Clear old plans and routine days
        if let existingPlans = try? modelContext.fetch(FetchDescriptor<CommitmentPlan>()) {
            for p in existingPlans { modelContext.delete(p) }
        }
        if let existingDays = try? modelContext.fetch(FetchDescriptor<RoutineDay>()) {
            for d in existingDays { modelContext.delete(d) }
        }
        if let existingCheckIns = try? modelContext.fetch(FetchDescriptor<CheckIn>()) {
            for c in existingCheckIns { modelContext.delete(c) }
        }

        // 2. Create and insert active plan
        let plan = CommitmentPlan(
            name: selectedTemplate.name,
            durationDays: selectedTemplate.durationDays,
            stakeCents: selectedTemplate.stakeCents,
            startDate: Calendar.current.startOfDay(for: .now),
            isActive: true
        )
        modelContext.insert(plan)

        // 3. Insert routine days
        for (day, focus) in focusByDay {
            modelContext.insert(RoutineDay(weekday: day, focus: focus))
        }

        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()

        onFinish()
    }
}

// MARK: - Step 1: The Hook
private struct Step1HookView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: DoTheme.Space.lg) {
            Spacer()

            VictoryEmblemView(size: 140)
                .padding(.bottom, DoTheme.Space.sm)

            VStack(spacing: DoTheme.Space.xs) {
                Text("DO OR DIE")
                    .font(DoTheme.Typography.body(13, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2.5)

                Text("Commit or don't.\nThere is no in-between.")
                    .font(DoTheme.Typography.display(32, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DoTheme.Color.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Not a workout logger. A zero-excuse accountability system for people done quitting.")
                    .font(DoTheme.Typography.body(15))
                    .foregroundStyle(DoTheme.Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DoTheme.Space.sm)
                    .padding(.top, DoTheme.Space.xs)
            }

            Spacer()

            PillButton(title: "I'm ready", style: .comb, action: onNext)
                .padding(.bottom, DoTheme.Space.md)
        }
        .padding(.horizontal, DoTheme.Space.md)
    }
}

// MARK: - Step 2: Past Failure Pattern
private struct Step2PastPatternView: View {
    @Binding var selected: String?
    let onNext: () -> Void

    private let options = [
        "1 – 2 times",
        "3 – 5 times",
        "Lost count... I start and stop constantly"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DoTheme.Space.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text("THE PATTERN")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("How many routines have you started and quit?")
                    .font(DoTheme.Typography.display(26, weight: .bold))
                    .foregroundStyle(DoTheme.Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, DoTheme.Space.md)

            VStack(spacing: DoTheme.Space.sm) {
                ForEach(options, id: \.self) { opt in
                    QuizOptionCard(
                        text: opt,
                        isSelected: selected == opt,
                        onSelect: {
                            selected = opt
                            HapticEngine.impact(.light)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                onNext()
                            }
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, DoTheme.Space.md)
    }
}

// MARK: - Step 3: Root Cause
private struct Step3RootCauseView: View {
    @Binding var selected: String?
    let onNext: () -> Void

    private let options = [
        ("bolt.slash.fill", "Missed one day, felt guilty, quit entirely"),
        ("person.2.fill", "Nobody held me accountable. Quitting was too easy."),
        ("list.bullet.clipboard.fill", "Tracking reps and sets felt like homework")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DoTheme.Space.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text("THE DIAGNOSIS")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("What's the #1 reason you stopped?")
                    .font(DoTheme.Typography.display(26, weight: .bold))
                    .foregroundStyle(DoTheme.Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, DoTheme.Space.md)

            VStack(spacing: DoTheme.Space.sm) {
                ForEach(options, id: \.1) { iconName, text in
                    QuizOptionCard(
                        systemImage: iconName,
                        text: text,
                        isSelected: selected == text,
                        onSelect: {
                            selected = text
                            HapticEngine.impact(.light)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                onNext()
                            }
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, DoTheme.Space.md)
    }
}

// MARK: - Step 4: The Science of Stakes (Black Dark Card)
private struct Step4ScienceView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: DoTheme.Space.lg) {
            Spacer()

            // Black Card matching HomePage top StreakHero
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("LOSS AVERSION")
                        .font(DoTheme.Typography.body(11, weight: .bold))
                        .foregroundStyle(DoTheme.Color.gold)
                        .tracking(1.5)
                    Spacer()
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DoTheme.Color.gold)
                }

                Text("Willpower alone barely works. A real stake works.")
                    .font(DoTheme.Typography.title)
                    .foregroundStyle(DoTheme.Color.onDark)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(DoTheme.Color.borderOnDark)

                // Adherence comparison
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Standard Workout Apps")
                                .font(DoTheme.Typography.body(12, weight: .semibold))
                                .foregroundStyle(DoTheme.Color.mutedOnDark)
                            Spacer()
                            Text("18% Adherence")
                                .font(DoTheme.Typography.body(12, weight: .bold))
                                .foregroundStyle(DoTheme.Color.mutedOnDark)
                        }
                        GeometryReader { g in
                            Capsule().fill(DoTheme.Color.borderOnDark)
                                .overlay(
                                    Capsule().fill(Color.white.opacity(0.35))
                                        .frame(width: g.size.width * 0.18),
                                    alignment: .leading
                                )
                        }
                        .frame(height: 8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Do or Die Commitment")
                                .font(DoTheme.Typography.body(12, weight: .bold))
                                .foregroundStyle(DoTheme.Color.gold)
                            Spacer()
                            Text("87% Adherence")
                                .font(DoTheme.Typography.body(12, weight: .heavy))
                                .foregroundStyle(DoTheme.Color.gold)
                        }
                        GeometryReader { g in
                            Capsule().fill(DoTheme.Color.borderOnDark)
                                .overlay(
                                    Capsule().fill(DoTheme.Color.gold)
                                        .frame(width: g.size.width * 0.87),
                                    alignment: .leading
                                )
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding(DoTheme.Space.md)
            .background(
                RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                    .fill(DoTheme.Color.gameInk)
                    .overlay(
                        RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                            .strokeBorder(DoTheme.Color.borderOnDark, lineWidth: 1)
                    )
                    .doShadow(DoTheme.Shadow.elevated)
            )

            VStack(spacing: DoTheme.Space.xs) {
                Text("THE SCIENCE")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("Willpower is a trap.\nLoss aversion works.")
                    .font(DoTheme.Typography.display(28, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DoTheme.Color.ink)

                Text("Put something on the line, and quitting stops being free.")
                    .font(DoTheme.Typography.body(14))
                    .foregroundStyle(DoTheme.Color.muted)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            PillButton(title: "Show me the rule", style: .comb, action: onNext)
                .padding(.bottom, DoTheme.Space.md)
        }
        .padding(.horizontal, DoTheme.Space.md)
    }
}

// MARK: - Step 5: The Law (Death Mechanic)
private struct Step5TheLawView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: DoTheme.Space.md) {
            Spacer()

            DeathEmblemView(size: 130)

            VStack(spacing: DoTheme.Space.xs) {
                Text("THE ONE RULE")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2.5)

                Text("Show up or Die.")
                    .font(DoTheme.Typography.display(34, weight: .black))
                    .foregroundStyle(DoTheme.Color.ink)

                Text("Miss one workout and your streak dies. Progress resets to Day 1. No pauses, no excuses.")
                    .font(DoTheme.Typography.body(14))
                    .foregroundStyle(DoTheme.Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DoTheme.Space.sm)
            }

            Spacer()

            PillButton(title: "Build my schedule", style: .comb, action: onNext)
                .padding(.bottom, DoTheme.Space.md)
        }
        .padding(.horizontal, DoTheme.Space.md)
    }
}

// MARK: - Step 6: Build Your Week (Split Setup)
private struct Step6SplitSetupView: View {
    @Binding var focusByDay: [Weekday: MuscleGroup]
    let onNext: () -> Void

    private var assignedCount: Int {
        focusByDay.values.filter { $0 != .rest }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SCHEDULE")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("Lock your weekly split.")
                    .font(DoTheme.Typography.display(26, weight: .bold))
                    .foregroundStyle(DoTheme.Color.ink)

                Text("Every day has a job. Workout days are promises. Rest days are free.")
                    .font(DoTheme.Typography.body(13))
                    .foregroundStyle(DoTheme.Color.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DoTheme.Space.sm)
            .padding(.bottom, DoTheme.Space.sm)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Weekday.allCases) { day in
                        FocusPickerRow(
                            label: day.short,
                            focus: focusByDay[day] ?? .rest,
                            onSelect: {
                                focusByDay[day] = $0
                                HapticEngine.impact(.light)
                            }
                        )
                    }
                }
                .padding(.bottom, DoTheme.Space.sm)
            }

            PillButton(
                title: assignedCount == 0 ? "Select at least 1 workout day" : "Lock \(assignedCount) days ➔ Next",
                style: .comb,
                action: onNext
            )
            .disabled(assignedCount == 0)
            .opacity(assignedCount == 0 ? 0.5 : 1.0)
            .padding(.top, DoTheme.Space.xs)
            .padding(.bottom, DoTheme.Space.md)
        }
        .padding(.horizontal, DoTheme.Space.md)
    }
}

// MARK: - Step 7: Pick Your Plan (Carousel with High-Contrast Dots)
private struct Step7PlanCarouselView: View {
    @Binding var selectedIndex: Int
    let onNext: () -> Void

    private var selected: PlanTemplate {
        PlanCatalog.all[selectedIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("THE CONTRACT")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("Choose your stakes.")
                    .font(DoTheme.Typography.display(26, weight: .bold))
                    .foregroundStyle(DoTheme.Color.ink)

                Text("Pick the duration and stakes you're willing to defend.")
                    .font(DoTheme.Typography.body(13))
                    .foregroundStyle(DoTheme.Color.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DoTheme.Space.sm)
            .padding(.bottom, DoTheme.Space.sm)

            // Card carousel
            PlanCarousel(selectedIndex: $selectedIndex)

            // High-Contrast Page dots
            HStack(spacing: 8) {
                ForEach(PlanCatalog.all.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == selectedIndex ? DoTheme.Color.comb : Color.black.opacity(0.28))
                        .frame(width: i == selectedIndex ? 24 : 6, height: 6)
                }
            }
            .animation(DoTheme.Motion.snappy, value: selectedIndex)
            .padding(.vertical, DoTheme.Space.sm)

            Spacer()

            PillButton(title: "Select \(selected.name) (\(selected.durationDays)d)", style: .comb, action: onNext)
                .padding(.bottom, DoTheme.Space.md)
        }
        .padding(.horizontal, DoTheme.Space.md)
    }
}

// MARK: - Step 8: Identity Anchor
private struct Step8IdentityView: View {
    @Binding var selected: String?
    let onNext: () -> Void

    private let options = [
        ("flame.fill", "Build unbreakable mental discipline"),
        ("trophy.fill", "Prove to myself that I can finish what I start"),
        ("arrow.up.forward.circle.fill", "Stop making excuses and transform my life")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DoTheme.Space.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text("YOUR WHY")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("Why are you making this commitment now?")
                    .font(DoTheme.Typography.display(26, weight: .bold))
                    .foregroundStyle(DoTheme.Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, DoTheme.Space.md)

            VStack(spacing: DoTheme.Space.sm) {
                ForEach(options, id: \.1) { iconName, text in
                    QuizOptionCard(
                        systemImage: iconName,
                        text: text,
                        isSelected: selected == text,
                        onSelect: {
                            selected = text
                            HapticEngine.impact(.light)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                onNext()
                            }
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, DoTheme.Space.md)
    }
}

// MARK: - Step 9: Generating Contract (Dark Card)
private struct Step9ContractGenView: View {
    let template: PlanTemplate
    let workingDays: Int
    let onNext: () -> Void

    @State private var item1 = false
    @State private var item2 = false
    @State private var item3 = false
    @State private var item4 = false
    @State private var ready = false

    var body: some View {
        VStack(spacing: DoTheme.Space.lg) {
            Spacer()

            VStack(spacing: 6) {
                Text("GENERATING AGREEMENT")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2)

                Text("Locking your contract...")
                    .font(DoTheme.Typography.display(26, weight: .bold))
                    .foregroundStyle(DoTheme.Color.ink)
            }

            // Dark Contract Summary Card
            VStack(alignment: .leading, spacing: 14) {
                contractItem(title: "Target Plan", value: "\(template.name) (\(template.durationDays) Days)", active: item1)
                contractItem(title: "Weekly Workouts", value: "\(workingDays) Days / Week", active: item2)
                contractItem(title: "Stakes Committed", value: "\(PurchaseManager.shared.localizedPrice(for: template)) / Streak Survival", active: item3)
                contractItem(title: "Zero-Excuse Protocol", value: "Active • Miss = Wipeout", active: item4)
            }
            .padding(DoTheme.Space.md)
            .background(
                RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                    .fill(DoTheme.Color.gameInk)
                    .overlay(
                        RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                            .strokeBorder(DoTheme.Color.borderOnDark, lineWidth: 1)
                    )
                    .doShadow(DoTheme.Shadow.elevated)
            )

            Spacer()

            PillButton(title: "Review and sign", style: .comb, action: onNext)
                .disabled(!ready)
                .opacity(ready ? 1 : 0.5)
                .padding(.bottom, DoTheme.Space.md)
        }
        .padding(.horizontal, DoTheme.Space.md)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { withAnimation { item1 = true }; HapticEngine.impact(.light) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation { item2 = true }; HapticEngine.impact(.light) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { withAnimation { item3 = true }; HapticEngine.impact(.light) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { withAnimation { item4 = true; ready = true }; HapticEngine.notification(.success) }
        }
    }

    private func contractItem(title: String, value: String, active: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(active ? DoTheme.Color.gold : DoTheme.Color.mutedOnDark)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DoTheme.Typography.body(11, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.mutedOnDark)
                Text(value)
                    .font(DoTheme.Typography.body(14, weight: .bold))
                    .foregroundStyle(DoTheme.Color.onDark)
            }
            Spacer()
        }
    }
}

// MARK: - Step 10: The Blood Oath / Hold to Commit (Dark Commitment Card)
private struct Step10OathView: View {
    let template: PlanTemplate
    let workingDays: Int
    let onComplete: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var timer: Timer? = nil

    var body: some View {
        VStack(spacing: DoTheme.Space.md) {
            Spacer()

            VStack(spacing: 6) {
                Text("FINAL PLEDGE")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(DoTheme.Color.comb)
                    .tracking(2.5)

                Text("Seal your commitment.")
                    .font(DoTheme.Typography.display(30, weight: .black))
                    .foregroundStyle(DoTheme.Color.ink)

                Text("Hold below and commit to all \(template.durationDays) days. No missed sessions.")
                    .font(DoTheme.Typography.body(14))
                    .foregroundStyle(DoTheme.Color.muted)
                    .multilineTextAlignment(.center)
            }

            // Dark Summary Oath Card matching StreakHero
            VStack(spacing: DoTheme.Space.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("THE CONTRACT")
                            .font(DoTheme.Typography.body(11, weight: .bold))
                            .foregroundStyle(DoTheme.Color.mutedOnDark)
                            .tracking(1.5)
                        Text(template.name)
                            .font(DoTheme.Typography.display(22, weight: .heavy))
                            .foregroundStyle(DoTheme.Color.onDark)
                    }
                    Spacer()
                    Text(PurchaseManager.shared.localizedPrice(for: template))
                        .font(DoTheme.Typography.display(22, weight: .bold))
                        .foregroundStyle(DoTheme.Color.gold)
                }

                Divider()
                    .overlay(DoTheme.Color.borderOnDark)

                HStack {
                    Label("\(template.durationDays) Days", systemImage: "flame.fill")
                        .font(DoTheme.Typography.body(13, weight: .bold))
                        .foregroundStyle(DoTheme.Color.onDark)
                    Spacer()
                    Label("\(workingDays) Workouts/Wk", systemImage: "calendar")
                        .font(DoTheme.Typography.body(13, weight: .bold))
                        .foregroundStyle(DoTheme.Color.onDark)
                }
            }
            .padding(DoTheme.Space.md)
            .background(
                RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                    .fill(DoTheme.Color.gameInk)
                    .overlay(
                        RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                            .strokeBorder(DoTheme.Color.comb.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: DoTheme.Color.comb.opacity(0.2), radius: 16, y: 6)
            )
            .padding(.horizontal, DoTheme.Space.xs)

            Spacer()

            // Hold To Commit Button
            VStack(spacing: 8) {
                ZStack {
                    // Progress fill background
                    RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                        .fill(DoTheme.Color.shell)
                        .overlay(
                            RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                                .strokeBorder(DoTheme.Color.borderOnLight, lineWidth: 1)
                        )
                        .doShadow(DoTheme.Shadow.resting)
                        .frame(height: 56)

                    // Fill meter
                    GeometryReader { g in
                        RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                            .fill(DoTheme.Color.comb)
                            .frame(width: g.size.width * holdProgress, height: 56)
                    }
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous))

                    HStack(spacing: 8) {
                        Image(systemName: holdProgress >= 1 ? "flame.fill" : "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text(holdProgress >= 1 ? "SEALING CONTRACT..." : (isHolding ? "HOLD TO SIGN..." : "HOLD TO SIGN CONTRACT"))
                            .font(DoTheme.Typography.body(15, weight: .heavy))
                            .tracking(0.5)
                    }
                    .foregroundStyle(isHolding || holdProgress > 0.4 ? DoTheme.Color.onDark : DoTheme.Color.ink)
                }
                .frame(height: 56)
                .scaleEffect(isHolding ? 0.97 : 1.0)
                .animation(.spring(response: 0.2), value: isHolding)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isHolding { startHold() }
                        }
                        .onEnded { _ in
                            cancelHold()
                        }
                )

                Text("Press and hold for 2 seconds to seal")
                    .font(DoTheme.Typography.body(11))
                    .foregroundStyle(DoTheme.Color.muted)
            }
            .padding(.bottom, DoTheme.Space.md)
        }
        .padding(.horizontal, DoTheme.Space.md)
    }

    private func startHold() {
        guard holdProgress < 1 else { return }
        isHolding = true
        HapticEngine.impact(.medium)

        timer?.invalidate()
        let step: CGFloat = 0.05
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { t in
            withAnimation(.linear(duration: 0.05)) {
                holdProgress = min(holdProgress + step, 1.0)
            }
            if holdProgress >= 1.0 {
                t.invalidate()
                HapticEngine.notification(.success)
                executePurchase()
            } else if Int(holdProgress * 100) % 25 == 0 {
                HapticEngine.impact(.light)
            }
        }
    }

    private func executePurchase() {
        Task {
            do {
                let success = try await PurchaseManager.shared.purchase(plan: template)
                if success {
                    onComplete()
                } else {
                    cancelHold()
                }
            } catch {
                cancelHold()
            }
        }
    }

    private func cancelHold() {
        guard holdProgress < 1.0 || isHolding else { return }
        isHolding = false
        timer?.invalidate()
        timer = nil
        withAnimation(.easeOut(duration: 0.25)) {
            holdProgress = 0
        }
    }
}

// MARK: - Reusable Quiz Option Card
private struct QuizOptionCard: View {
    var systemImage: String? = nil
    let text: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isSelected ? DoTheme.Color.comb : DoTheme.Color.muted)
                        .frame(width: 24)
                }

                Text(text)
                    .font(DoTheme.Typography.body(15, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? DoTheme.Color.comb : DoTheme.Color.ink)
                    .multilineTextAlignment(.leading)

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? DoTheme.Color.comb : DoTheme.Color.pillGray, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(DoTheme.Color.comb)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, DoTheme.Space.md)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                    .fill(isSelected ? DoTheme.Color.comb.opacity(0.06) : DoTheme.Color.shell)
                    .overlay(
                        RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                            .strokeBorder(
                                isSelected ? DoTheme.Color.comb : DoTheme.Color.borderOnLight,
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                    .doShadow(DoTheme.Shadow.resting)
            )
        }
        .buttonStyle(.plain)
    }
}
