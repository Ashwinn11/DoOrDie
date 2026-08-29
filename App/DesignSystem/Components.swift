import SwiftUI

struct PillButton: View {
    let title: String
    var systemImage: String? = nil
    var style: Style = .ink
    var action: () -> Void

    enum Style {
        case ink, comb, shell, gold

        var background: SwiftUI.Color {
            switch self {
            case .ink: DoTheme.Color.ink
            case .comb: DoTheme.Color.comb
            case .shell: DoTheme.Color.shell
            case .gold: DoTheme.Color.gold
            }
        }

        var foreground: SwiftUI.Color {
            switch self {
            case .ink, .comb: .white
            case .shell, .gold: DoTheme.Color.ink
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(DoTheme.Typography.body(17, weight: .semibold))
            .foregroundStyle(style.foreground)
            .padding(.vertical, 15)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(style.background, in: RoundedRectangle(cornerRadius: DoTheme.Radius.button, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .containerRelativeFrame(.horizontal) { width, _ in width * 0.75 }
    }
}

/// Matches tryclucky.com's snappy, overshoot-free press feedback.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DoTheme.Motion.snappy, value: configuration.isPressed)
    }
}

struct DarkCard<Content: View>: View {
    var padding: CGFloat = DoTheme.Space.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(DoTheme.Color.gameInk, in: RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous))
    }
}

struct ShellCard<Content: View>: View {
    var padding: CGFloat = DoTheme.Space.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(DoTheme.Color.shell, in: RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous))
    }
}

/// The one plan-selection card look, shared by onboarding's PlanPickerView
/// and Profile's ChangePlanSheet so switching plans never feels like a
/// different screen.
struct PlanOptionCard: View {
    let plan: PlanTemplate
    let isSelected: Bool
    var badge: String? = nil

    var body: some View {
        HStack(spacing: DoTheme.Space.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(plan.name)
                        .font(DoTheme.Typography.display(20, weight: .bold))
                        .foregroundStyle(isSelected ? .white : DoTheme.Color.ink)
                    if let badge {
                        Chip(text: badge, tint: DoTheme.Color.gold)
                    }
                }
                Text(plan.tagline)
                    .font(DoTheme.Typography.body(13))
                    .foregroundStyle(isSelected ? DoTheme.Color.mutedOnDark : DoTheme.Color.muted)
                Text("\(plan.durationDays) days")
                    .font(DoTheme.Typography.body(12, weight: .semibold))
                    .foregroundStyle(isSelected ? DoTheme.Color.gold : DoTheme.Color.comb)
            }

            Spacer()

            Text(plan.stakeDisplay)
                .font(DoTheme.Typography.display(22, weight: .bold))
                .foregroundStyle(isSelected ? DoTheme.Color.gold : DoTheme.Color.ink)
        }
        .padding(DoTheme.Space.md)
        .background(
            isSelected ? DoTheme.Color.gameInk : DoTheme.Color.shell,
            in: RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DoTheme.Radius.card, style: .continuous)
                .strokeBorder(isSelected ? Color.clear : DoTheme.Color.ink.opacity(0.06))
        )
    }
}

/// A tappable day/focus row backed by a native Menu — shared by onboarding's
/// routine setup and Profile's week editor so both look identical.
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
                    .foregroundStyle(focus == .rest ? DoTheme.Color.ink : .white)
                    .frame(width: 44, alignment: .leading)

                Image(systemName: focus.systemImage)
                    .foregroundStyle(focus == .rest ? DoTheme.Color.muted : DoTheme.Color.gold)

                Text(focus.label)
                    .font(DoTheme.Typography.body(16, weight: .semibold))
                    .foregroundStyle(focus == .rest ? DoTheme.Color.ink : .white)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(focus == .rest ? DoTheme.Color.muted : DoTheme.Color.mutedOnDark)
            }
            .padding(.horizontal, DoTheme.Space.md)
            .padding(.vertical, 14)
            .background(
                focus == .rest ? DoTheme.Color.shell : DoTheme.Color.gameInk,
                in: RoundedRectangle(cornerRadius: DoTheme.Radius.tile, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DoTheme.Radius.tile, style: .continuous)
                    .strokeBorder(focus == .rest ? DoTheme.Color.ink.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct Chip: View {
    let text: String
    var tint: SwiftUI.Color = DoTheme.Color.gold
    var textColor: SwiftUI.Color = DoTheme.Color.ink

    var body: some View {
        Text(text)
            .font(DoTheme.Typography.body(13, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tint, in: Capsule())
    }
}
