import SwiftUI

struct PillButton: View {
    let title: String
    var systemImage: String? = nil
    var style: Style = .coral
    var action: () -> Void

    enum Style {
        case coral, honey, lilac, glassShell, ink, comb, gold, shell

        var foreground: SwiftUI.Color {
            switch self {
            case .coral, .comb, .lilac, .ink: .white
            case .honey, .gold, .glassShell, .shell: DoTheme.Color.ink
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
            }
            .font(DoTheme.Typography.display(17, weight: .bold))
            .foregroundStyle(style.foreground)
            .padding(.vertical, 17)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background {
                buttonBackground
            }
            .buttonShadow(for: style)
        }
        .buttonStyle(PressableButtonStyle())
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .coral, .comb:
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [SwiftUI.Color(hex: 0xFA7268), SwiftUI.Color(hex: 0xEB5B56)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        case .lilac:
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [SwiftUI.Color(hex: 0xC885C2), SwiftUI.Color(hex: 0xB36FA8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        case .glassShell, .shell, .honey, .gold:
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.96))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.5), Color.black.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        case .ink:
            Capsule().fill(DoTheme.Color.ink)
        }
    }
}

private extension View {
    @ViewBuilder
    func buttonShadow(for style: PillButton.Style) -> some View {
        switch style {
        case .coral, .comb:
            self.shadow(color: SwiftUI.Color(hex: 0xF06560).opacity(0.35), radius: 18, x: 0, y: 8)
        case .lilac:
            self.shadow(color: SwiftUI.Color(hex: 0xBA79AF).opacity(0.35), radius: 18, x: 0, y: 8)
        case .glassShell, .shell, .honey, .gold:
            self
                .shadow(color: Color.black.opacity(0.07), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        case .ink:
            self.shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 6)
        }
    }
}

/// Snappy press feedback with light haptic impact.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DoTheme.Motion.snappy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { HapticEngine.impact(.light) }
            }
    }
}

struct DarkCard<Content: View>: View {
    var padding: CGFloat = DoTheme.Space.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(DoTheme.Color.gameInk, in: RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)
    }
}

struct ShellCard<Content: View>: View {
    var padding: CGFloat = DoTheme.Space.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.96))

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.5),
                                    Color.black.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.07), radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

/// The one plan-selection card look, shared by onboarding's plan carousel
/// and Profile's ChangePlanSheet.
struct PlanOptionCard: View {
    let plan: PlanTemplate
    let isSelected: Bool
    var badge: String? = nil

    var body: some View {
        HStack(spacing: DoTheme.Space.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name)
                    .font(DoTheme.Typography.display(20, weight: .bold))
                    .foregroundStyle(isSelected ? .white : DoTheme.Color.ink)
                Text(plan.tagline)
                    .font(DoTheme.Typography.body(13))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : DoTheme.Color.muted)
                Text("\(plan.durationDays) days")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(isSelected ? .white : plan.accentColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if let badge {
                    Chip(text: badge, tint: .white.opacity(0.3), textColor: .white)
                }
                Text(PurchaseManager.shared.localizedPrice(for: plan))
                    .font(DoTheme.Typography.display(22, weight: .bold))
                    .foregroundStyle(isSelected ? .white : DoTheme.Color.ink)
            }
        }
        .padding(DoTheme.Space.md)
        .background(
            isSelected ? plan.paletteBackground : DoTheme.Color.shell,
            in: RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
        )
        .shadow(
            color: isSelected ? plan.accentColor.opacity(0.3) : Color.black.opacity(0.04),
            radius: isSelected ? 16 : 8,
            y: isSelected ? 6 : 2
        )
    }
}

/// The swipeable plan carousel — shared by onboarding and ChangePlanSheet.
struct PlanCarousel: View {
    @Binding var selectedIndex: Int

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * 0.76
            let spacing: CGFloat = 16

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(Array(PlanCatalog.all.enumerated()), id: \.offset) { index, plan in
                        PlanCard(plan: plan, isSelected: index == selectedIndex)
                            .frame(width: cardWidth)
                            .scrollTransition(.animated(DoTheme.Motion.snappy)) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.94)
                                    .opacity(phase.isIdentity ? 1 : 0.75)
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
        .frame(height: 380)
    }
}

/// Unified Single-Section Plan Card with custom tier palette background.
struct PlanCard: View {
    let plan: PlanTemplate
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // SVG hero
            ZStack {
                CyclingSVGView(frameImageNames: plan.heroFrameNames)
                    .foregroundStyle(.white)
                    .frame(width: 170, height: 170)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 210)

            // Info section
            VStack(alignment: .leading, spacing: DoTheme.Space.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(plan.name.uppercased())
                        .font(DoTheme.Typography.display(22, weight: .heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(PurchaseManager.shared.localizedPrice(for: plan))
                        .font(DoTheme.Typography.display(18, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25), in: Capsule())
                }

                Text(plan.tagline)
                    .font(DoTheme.Typography.body(13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineLimit(2)

                Text("\(plan.durationDays) days commitment")
                    .font(DoTheme.Typography.body(12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .padding(.top, 2)
            }
            .padding(DoTheme.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(plan.paletteBackground)
        .clipShape(RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous))
        .shadow(
            color: plan.accentColor.opacity(isSelected ? 0.35 : 0.15),
            radius: isSelected ? 20 : 10,
            y: isSelected ? 8 : 4
        )
        .scaleEffect(isSelected ? 1.0 : 0.98)
    }
}

/// A tappable day/focus row backed by a native Menu.
struct FocusPickerRow: View {
    let label: String
    let focus: MuscleGroup
    let onSelect: (MuscleGroup) -> Void

    var body: some View {
        Menu {
            ForEach(MuscleGroup.allCases) { group in
                Button {
                    onSelect(group)
                } label: {
                    if group == focus {
                        Label(group.label, systemImage: group.systemImage)
                        Image(systemName: "checkmark")
                    } else {
                        Label(group.label, systemImage: group.systemImage)
                    }
                }
            }
        } label: {
            HStack(spacing: DoTheme.Space.sm) {
                Text(label)
                    .font(DoTheme.Typography.display(15, weight: .bold))
                    .foregroundStyle(DoTheme.Color.ink)
                    .frame(width: 44, alignment: .leading)

                Image(systemName: focus.systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(focus == .rest ? DoTheme.Color.muted : DoTheme.Color.coral)

                Text(focus.label)
                    .font(DoTheme.Typography.body(16, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.ink)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.muted)
            }
            .padding(.horizontal, DoTheme.Space.md)
            .padding(.vertical, 16)
            .liquidGlassPill()
        }
        .buttonStyle(.plain)
    }
}

struct Chip: View {
    let text: String
    var tint: SwiftUI.Color = DoTheme.Color.shell
    var textColor: SwiftUI.Color = DoTheme.Color.ink

    var body: some View {
        Text(text)
            .font(DoTheme.Typography.body(13, weight: .bold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(tint, in: Capsule())
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}
