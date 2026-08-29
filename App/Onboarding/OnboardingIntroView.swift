import SwiftUI

private struct IntroPage {
    let eyebrow: String
    let title: String
    let body: String
    let systemImage: String
}

private let pages: [IntroPage] = [
    IntroPage(
        eyebrow: "DO OR DIE",
        title: "Commit\nor don't.",
        body: "Pick a plan, lock in your week, and show up. No snoozing, no excuses.",
        systemImage: "flame.fill"
    ),
    IntroPage(
        eyebrow: "YOUR WEEK",
        title: "Every day\nhas a job.",
        body: "Chest on Sunday. Rest on Saturday. You build the split — we hold you to it.",
        systemImage: "calendar"
    ),
    IntroPage(
        eyebrow: "THE STAKES",
        title: "Miss it,\nit dies.",
        body: "Miss a day, forfeit the stake, start over.",
        systemImage: "bolt.slash.fill"
    ),
]

struct OnboardingIntroView: View {
    let onFinish: () -> Void
    @State private var index = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                    PageView(page: page, isActive: i == index).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: DoTheme.Space.md) {
                HStack(spacing: 6) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == index ? DoTheme.Color.comb : DoTheme.Color.pillGray)
                            .frame(width: i == index ? 20 : 6, height: 6)
                    }
                }
                .animation(DoTheme.Motion.snappy, value: index)

                PillButton(
                    title: index == pages.count - 1 ? "Let's go" : "Next",
                    style: .comb
                ) {
                    HapticEngine.impact(.light)
                    if index == pages.count - 1 {
                        onFinish()
                    } else {
                        withAnimation(DoTheme.Motion.snappy) { index += 1 }
                    }
                }

                if index < pages.count - 1 {
                    Button("Skip") {
                        HapticEngine.impact(.light)
                        onFinish()
                    }
                    .font(DoTheme.Typography.body(14, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.muted)
                } else {
                    Color.clear.frame(height: 20)
                }
            }
            .padding(DoTheme.Space.md)
            .padding(.bottom, DoTheme.Space.sm)
        }
        .background(DoTheme.Color.bg.ignoresSafeArea())
    }
}

private struct PageView: View {
    let page: IntroPage
    let isActive: Bool

    @State private var iconBounced = false

    var body: some View {
        VStack(alignment: .leading, spacing: DoTheme.Space.md) {
            Spacer()

            Image(systemName: page.systemImage)
                .font(.system(size: 44))
                .foregroundStyle(DoTheme.Color.gold)
                .frame(width: 84, height: 84)
                .background(DoTheme.Color.gameInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .scaleEffect(iconBounced ? 1 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.05), value: iconBounced)

            Text(page.eyebrow)
                .font(DoTheme.Typography.body(13, weight: .bold))
                .foregroundStyle(DoTheme.Color.comb)
                .tracking(2)
                .opacity(iconBounced ? 1 : 0)
                .offset(x: iconBounced ? 0 : 20)
                .animation(DoTheme.Motion.easeOut.delay(0.1), value: iconBounced)

            Text(page.title)
                .font(DoTheme.Typography.hero)
                .displayTracking(48)
                .foregroundStyle(DoTheme.Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(iconBounced ? 1 : 0)
                .offset(x: iconBounced ? 0 : 20)
                .animation(DoTheme.Motion.easeOut.delay(0.15), value: iconBounced)

            Text(page.body)
                .font(DoTheme.Typography.body(16))
                .foregroundStyle(DoTheme.Color.muted)
                .opacity(iconBounced ? 1 : 0)
                .offset(x: iconBounced ? 0 : 20)
                .animation(DoTheme.Motion.easeOut.delay(0.2), value: iconBounced)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DoTheme.Space.lg)
        .onAppear { iconBounced = true }
        .onChange(of: isActive) { _, active in
            if active {
                iconBounced = false
                // Small delay to let the TabView scroll settle, then animate in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    iconBounced = true
                }
            }
        }
    }
}

#Preview {
    OnboardingIntroView(onFinish: {})
}
