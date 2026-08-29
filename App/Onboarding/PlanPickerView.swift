import SwiftData
import SwiftUI
import WidgetKit

struct PlanPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedIndex = 1 // Default to "Committed"

    private var selected: PlanTemplate { PlanCatalog.all[selectedIndex] }

    var body: some View {
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

                Text("Miss a day, forfeit the stake, start over.")
                    .font(DoTheme.Typography.body(15))
                    .foregroundStyle(DoTheme.Color.muted)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DoTheme.Space.md)
            .padding(.top, DoTheme.Space.lg)
            .padding(.bottom, DoTheme.Space.lg)

            // Card carousel
            PlanCarousel(selectedIndex: $selectedIndex)

            // Page dots
            HStack(spacing: 6) {
                ForEach(PlanCatalog.all.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == selectedIndex ? DoTheme.Color.comb : DoTheme.Color.pillGray)
                        .frame(width: i == selectedIndex ? 20 : 6, height: 6)
                }
            }
            .animation(DoTheme.Motion.snappy, value: selectedIndex)
            .padding(.top, DoTheme.Space.md)

            Spacer()

            // CTA
            VStack(spacing: DoTheme.Space.xs) {
                PillButton(title: "Commit — \(selected.stakeDisplay)", style: .comb) {
                    HapticEngine.impact(.medium)
                    startPlan()
                }
                Text("Stakes aren't charged yet in this build.")
                    .font(DoTheme.Typography.body(12))
                    .foregroundStyle(DoTheme.Color.muted)
            }
            .padding(DoTheme.Space.md)
        }
        .background(DoTheme.Color.bg.ignoresSafeArea())
    }

    private func startPlan() {
        PlanLifecycle.startPlan(template: selected, in: modelContext)
    }
}

// MARK: - Carousel

struct PlanCarousel: View {
    @Binding var selectedIndex: Int

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * 0.72
            let spacing: CGFloat = 16

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(Array(PlanCatalog.all.enumerated()), id: \.offset) { index, plan in
                        PlanCard(plan: plan, isSelected: index == selectedIndex)
                            .frame(width: cardWidth)
                            .scrollTransition(.animated(DoTheme.Motion.snappy)) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.93)
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                            }
                            .onTapGesture {
                                HapticEngine.selection()
                                withAnimation(DoTheme.Motion.snappy) { selectedIndex = index }
                            }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, (geo.size.width - cardWidth) / 2)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding(
                get: { selectedIndex },
                set: { newVal in
                    if let v = newVal, v != selectedIndex {
                        HapticEngine.selection()
                        selectedIndex = v
                    }
                }
            ))
        }
        .frame(height: 360)
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: PlanTemplate
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // SVG hero
            ZStack {
                CyclingSVGView(frameImageNames: plan.heroFrameNames)
                    .foregroundStyle(.white)
                    .frame(width: 160, height: 160)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                LinearGradient(
                    colors: [DoTheme.Color.gameInk, plan.accentColor.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Info section
            VStack(alignment: .leading, spacing: DoTheme.Space.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(plan.name.uppercased())
                        .font(DoTheme.Typography.display(22, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(plan.stakeDisplay)
                        .font(DoTheme.Typography.display(18, weight: .bold))
                        .foregroundStyle(DoTheme.Color.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DoTheme.Color.gold.opacity(0.15), in: Capsule())
                }

                Text(plan.tagline)
                    .font(DoTheme.Typography.body(13))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)

                Text("\(plan.durationDays) days")
                    .font(DoTheme.Typography.body(13, weight: .semibold))
                    .foregroundStyle(plan.accentColor)
            }
            .padding(DoTheme.Space.md)
            .background(DoTheme.Color.gameInk)
        }
        .clipShape(RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                .strokeBorder(
                    isSelected ? plan.accentColor.opacity(0.6) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(isSelected ? 0.18 : 0.08), radius: isSelected ? 20 : 8, y: 6)
    }
}

#Preview {
    PlanPickerView()
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
