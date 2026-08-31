import SwiftData
import SwiftUI
import WidgetKit

struct PlanPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var routineDays: [RoutineDay]

    @State private var selectedIndex = 1 // Default to "Committed"
    @State private var isPurchasing = false

    private var selected: PlanTemplate { PlanCatalog.all[selectedIndex] }

    var body: some View {
        ZStack {
            DoTheme.Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: DoTheme.Space.xs) {
                    Text("DO OR DIE")
                        .font(DoTheme.Typography.body(13, weight: .bold))
                        .foregroundStyle(DoTheme.Color.comb)
                        .tracking(2)

                    Text("Pick your\ncommitment.")
                        .font(DoTheme.Typography.hero)
                        .displayTracking(48)
                        .foregroundStyle(DoTheme.Color.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Miss a day, lose the streak, start over.")
                        .font(DoTheme.Typography.body(15))
                        .foregroundStyle(DoTheme.Color.muted)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DoTheme.Space.md)
                .padding(.top, DoTheme.Space.lg)
                .padding(.bottom, DoTheme.Space.md)

                // Card carousel
                PlanCarousel(selectedIndex: $selectedIndex)

                // High-contrast page dots
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

                // CTA
                VStack(spacing: DoTheme.Space.xs) {
                    PillButton(
                        title: isPurchasing ? "Purchasing..." : "Commit — \(PurchaseManager.shared.localizedPrice(for: selected))",
                        style: .comb
                    ) {
                        startPlan()
                    }
                    .disabled(isPurchasing)
                }
                .padding(.horizontal, DoTheme.Space.md)
                .padding(.bottom, DoTheme.Space.lg)
            }
        }
    }

    private func startPlan() {
        HapticEngine.impact(.medium)
        isPurchasing = true

        Task {
            do {
                let success = try await PurchaseManager.shared.purchase(plan: selected)
                isPurchasing = false
                if success {
                    PlanLifecycle.startPlan(template: selected, in: modelContext)
                }
            } catch {
                isPurchasing = false
                print("DoOrDie: Plan picker purchase error: \(error)")
            }
        }
    }
}
