import SwiftUI
import WidgetKit

struct DoOrDieWidgetView: View {
    let entry: DoOrDieEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.durationDays == 0 {
            NoPlanView()
        } else {
            switch entry.outcome {
            case .failed(let diedOnDay):
                OutcomeView(kind: .failed, planName: entry.planName, dayNumber: diedOnDay, totalDays: entry.durationDays)
            case .completed:
                OutcomeView(kind: .completed, planName: entry.planName, dayNumber: entry.durationDays, totalDays: entry.durationDays)
            case .active(let dayNumber):
                switch family {
                case .systemSmall:
                    SmallGridView(entry: entry, dayNumber: dayNumber)
                default:
                    GridView(entry: entry)
                }
            }
        }
    }
}

private struct NoPlanView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundStyle(DoTheme.Color.comb)
            Text("No active plan")
                .font(DoTheme.Typography.body(13, weight: .semibold))
                .foregroundStyle(DoTheme.Color.ink)
            Text("Open Do or Die to start")
                .font(DoTheme.Typography.body(11))
                .foregroundStyle(DoTheme.Color.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(DoTheme.Color.bg, for: .widget)
    }
}

private struct OutcomeView: View {
    enum Kind { case failed, completed }
    let kind: Kind
    let planName: String
    let dayNumber: Int
    let totalDays: Int

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: kind == .failed ? "flame.fill" : "checkmark.seal.fill")
                .font(.system(size: 22))
                .foregroundStyle(kind == .failed ? DoTheme.Color.comb : DoTheme.Color.gold)
            Text(kind == .failed ? "YOU DIED" : "COMPLETE")
                .font(DoTheme.Typography.display(15, weight: .heavy))
                .foregroundStyle(DoTheme.Color.ink)
            Text(kind == .failed ? "Day \(dayNumber)/\(totalDays), \(planName)" : "\(totalDays)/\(totalDays), \(planName)")
                .font(DoTheme.Typography.body(11))
                .foregroundStyle(DoTheme.Color.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(DoTheme.Color.bg, for: .widget)
    }
}

private struct SmallGridView: View {
    let entry: DoOrDieEntry
    let dayNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.planName.uppercased())
                .font(DoTheme.Typography.body(10, weight: .bold))
                .foregroundStyle(DoTheme.Color.comb)
                .lineLimit(1)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(dayNumber)")
                    .font(DoTheme.Typography.display(38, weight: .heavy))
                    .foregroundStyle(DoTheme.Color.ink)
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(DoTheme.Color.comb)
            }

            Text("of \(entry.durationDays) days")
                .font(DoTheme.Typography.body(12, weight: .semibold))
                .foregroundStyle(DoTheme.Color.muted)

            Spacer()

            ProgressBar(progress: Double(dayNumber) / Double(entry.durationDays))
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(DoTheme.Color.bg, for: .widget)
    }
}

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.09))
                Capsule().fill(DoTheme.Color.comb)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 6)
    }
}

private struct GridView: View {
    let entry: DoOrDieEntry

    var body: some View {
        GeometryReader { geo in
            let layout = CellGridLayout.fit(count: entry.cells.count, in: geo.size, spacing: 3)

            // A separate SwiftUI view per cell (Image + background + frame,
            // up to 365 of them) hits WidgetKit's rendering complexity
            // ceiling and silently renders blank past ~90-100 cells. Canvas
            // draws the whole grid as one view instead — cheap regardless
            // of cell count. No header — plan name/day count removed so the
            // grid gets the full box, matching the Steps-widget reference.
            Canvas { context, _ in
                guard layout.columns > 0, layout.cellWidth > 0, layout.cellHeight > 0 else { return }
                let minDimension = min(layout.cellWidth, layout.cellHeight)
                for (index, cell) in entry.cells.enumerated() {
                    let row = index / layout.columns
                    let column = index % layout.columns
                    let rect = CGRect(
                        x: CGFloat(column) * (layout.cellWidth + layout.spacing),
                        y: CGFloat(row) * (layout.cellHeight + layout.spacing),
                        width: layout.cellWidth,
                        height: layout.cellHeight
                    )

                    // pillGray (#F3F3F3) is *lighter* than the widget's
                    // own bg (#EDEDED), so it's invisible here even
                    // though it reads fine on white in-app cards. Empty
                    // cells need a fill that actually contrasts against
                    // whatever's behind them.
                    let fillColor: Color = cell.isDone ? DoTheme.Color.gold : (cell.isToday ? DoTheme.Color.comb : Color.black.opacity(0.09))
                    context.fill(Path(roundedRect: rect, cornerRadius: max(minDimension * 0.28, 2)), with: .color(fillColor))

                    guard minDimension >= 4 else { continue }
                    let iconColor: Color = cell.isDone ? DoTheme.Color.ink : (cell.isToday ? .white : DoTheme.Color.muted)
                    let symbolName = cell.focus == .rest ? "moon.zzz.fill" : cell.focus.systemImage
                    let iconSize = max(minDimension * 0.6, 3)
                    // Image has no Image-returning .font/.foregroundColor
                    // overload (those resolve to the generic View
                    // modifiers, which resolve() rejects), so tint the
                    // resolved glyph with the standard Canvas trick:
                    // draw it, then mask-fill with .sourceIn.
                    let resolved = context.resolve(Image(systemName: symbolName))
                    let iconRect = rect.insetBy(dx: (rect.width - iconSize) / 2, dy: (rect.height - iconSize) / 2)
                    context.drawLayer { layer in
                        layer.draw(resolved, in: iconRect)
                        layer.blendMode = .sourceIn
                        layer.fill(Path(iconRect), with: .color(iconColor))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(DoTheme.Color.bg, for: .widget)
    }
}

/// Mimics a natural left-to-right reading grid (like the Steps widget this
/// is modeled on): fill a row with as many cells as fit at the largest
/// legible size, wrap to a new row only when needed, and only shrink the
/// cell size once row-wrapping alone can't fit everything in the height.
/// A near-square "block" layout (the previous approach) was wrong — it
/// left small day counts stacked in a tall, mostly-empty box instead of
/// spreading across the available width as one wide row.
struct CellGridLayout {
    let columns: Int
    let rows: Int
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let spacing: CGFloat

    static func fit(count: Int, in size: CGSize, spacing: CGFloat, minCell: CGFloat = 6, maxCell: CGFloat = 42) -> CellGridLayout {
        guard count > 0, size.width > spacing, size.height > spacing else {
            return CellGridLayout(columns: 0, rows: 0, cellWidth: 0, cellHeight: 0, spacing: spacing)
        }

        // Scan cell sizes from largest to smallest. For each, pack as many
        // columns as the width allows (capped at `count` — no point
        // reserving columns nothing will ever fill), derive the resulting
        // row count, and take the first (largest) size whose rows still
        // fit the height.
        var step = maxCell
        var chosenColumns = 1
        var chosenRows = count
        while step >= minCell {
            let widthColumns = max(1, Int((size.width + spacing) / (step + spacing)))
            let columns = min(widthColumns, count)
            let rows = Int(ceil(Double(count) / Double(columns)))
            let neededHeight = CGFloat(rows) * step + CGFloat(max(rows - 1, 0)) * spacing
            if neededHeight <= size.height {
                chosenColumns = columns
                chosenRows = rows
                break
            }
            step -= 0.5
        }
        if step < minCell {
            // Nothing fit even at the floor — pack at minCell and accept
            // whatever results; this is an extreme edge case only.
            chosenColumns = min(max(1, Int((size.width + spacing) / (minCell + spacing))), count)
            chosenRows = Int(ceil(Double(count) / Double(chosenColumns)))
        }

        // Stretch to use any leftover space in both axes exactly, now that
        // a sane (columns, rows) pair is settled.
        let rawWidth = (size.width - CGFloat(chosenColumns - 1) * spacing) / CGFloat(chosenColumns)
        let rawHeight = (size.height - CGFloat(chosenRows - 1) * spacing) / CGFloat(chosenRows)
        let cellWidth = max(min(rawWidth, maxCell), 3)
        let cellHeight = max(min(rawHeight, maxCell), 3)
        return CellGridLayout(columns: chosenColumns, rows: chosenRows, cellWidth: cellWidth, cellHeight: cellHeight, spacing: spacing)
    }
}

#Preview(as: .systemSmall) {
    DoOrDieWidget()
} timeline: {
    DoOrDieEntry.placeholder
}

#Preview(as: .systemMedium) {
    DoOrDieWidget()
} timeline: {
    DoOrDieEntry.placeholder
}

#Preview(as: .systemLarge) {
    DoOrDieWidget()
} timeline: {
    DoOrDieEntry.placeholder
}
