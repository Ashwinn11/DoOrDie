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
            case .active:
                switch family {
                case .systemSmall:
                    SmallGridView(entry: entry)
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
            // Illustrated Crest
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (kind == .failed ? DoTheme.Color.comb : DoTheme.Color.gold).opacity(0.35),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DoTheme.Color.gameInk)
                    .frame(width: 38, height: 38)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                (kind == .failed ? DoTheme.Color.comb : DoTheme.Color.gold).opacity(0.6),
                                lineWidth: 1.5
                            )
                    )

                if kind == .failed {
                    Image("ex-defeat-1")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, DoTheme.Color.comb],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 26, height: 26)
                } else {
                    Image("ex-overhead-press-3")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, DoTheme.Color.gold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 26, height: 26)
                }
            }

            Text(kind == .failed ? "YOU DIED" : "CHAMPION")
                .font(DoTheme.Typography.display(14, weight: .heavy))
                .foregroundStyle(DoTheme.Color.ink)
                .tracking(1)

            Text(kind == .failed ? "Died on Day \(dayNumber) of \(totalDays)" : "All \(totalDays) Days Complete")
                .font(DoTheme.Typography.body(10, weight: .medium))
                .foregroundStyle(DoTheme.Color.muted)
                .multilineTextAlignment(.center)
                .lineLimit(1)

            Text(planName.uppercased())
                .font(DoTheme.Typography.body(9, weight: .bold))
                .foregroundStyle(kind == .failed ? DoTheme.Color.comb : DoTheme.Color.gold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (kind == .failed ? DoTheme.Color.comb : DoTheme.Color.gold).opacity(0.12),
                    in: Capsule()
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(DoTheme.Color.bg, for: .widget)
    }
}

private struct SmallGridView: View {
    let entry: DoOrDieEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.planName.uppercased())
                .font(DoTheme.Typography.body(10, weight: .bold))
                .foregroundStyle(DoTheme.Color.comb)
                .lineLimit(1)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.streak)")
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

            ProgressBar(progress: Double(entry.streak) / Double(entry.durationDays))
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

            Canvas { context, size in
                guard layout.columns > 0, layout.cellSize > 0 else { return }
                let totalGridWidth = CGFloat(layout.columns) * layout.cellSize + CGFloat(layout.columns - 1) * layout.spacing
                let totalGridHeight = CGFloat(layout.rows) * layout.cellSize + CGFloat(layout.rows - 1) * layout.spacing
                let offsetX = max((size.width - totalGridWidth) / 2, 0)
                let offsetY = max((size.height - totalGridHeight) / 2, 0)

                for (index, cell) in entry.cells.enumerated() {
                    let row = index / layout.columns
                    let column = index % layout.columns
                    let rect = CGRect(
                        x: offsetX + CGFloat(column) * (layout.cellSize + layout.spacing),
                        y: offsetY + CGFloat(row) * (layout.cellSize + layout.spacing),
                        width: layout.cellSize,
                        height: layout.cellSize
                    )

                    let fillColor: Color = cell.isDone ? DoTheme.Color.gold : (cell.isToday ? DoTheme.Color.comb : Color.black.opacity(0.09))
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: max(layout.cellSize * 0.28, 2)),
                        with: .color(fillColor)
                    )

                    guard layout.cellSize >= 6 else { continue }
                    let iconColor: Color = cell.isDone ? DoTheme.Color.ink : (cell.isToday ? .white : DoTheme.Color.muted)
                    let symbolName = cell.focus == .rest ? "moon.zzz.fill" : cell.focus.systemImage
                    let iconSize = layout.cellSize * 0.58

                    let symbol = Text(Image(systemName: symbolName))
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundStyle(iconColor)
                    let resolved = context.resolve(symbol)
                    context.draw(resolved, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(DoTheme.Color.bg, for: .widget)
    }
}

/// Guarantees strict 1:1 square cells, fitting as many columns and rows
/// as possible without ever distorting or stretching the cell geometry.
struct CellGridLayout {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    let spacing: CGFloat

    static func fit(count: Int, in size: CGSize, spacing: CGFloat, minCell: CGFloat = 6, maxCell: CGFloat = 42) -> CellGridLayout {
        guard count > 0, size.width > spacing, size.height > spacing else {
            return CellGridLayout(columns: 0, rows: 0, cellSize: 0, spacing: spacing)
        }

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
            chosenColumns = min(max(1, Int((size.width + spacing) / (minCell + spacing))), count)
            chosenRows = Int(ceil(Double(count) / Double(chosenColumns)))
        }

        let maxFittingWidth = (size.width - CGFloat(chosenColumns - 1) * spacing) / CGFloat(chosenColumns)
        let maxFittingHeight = (size.height - CGFloat(chosenRows - 1) * spacing) / CGFloat(chosenRows)
        let cellSize = max(min(min(maxFittingWidth, maxFittingHeight), maxCell), 3)

        return CellGridLayout(columns: chosenColumns, rows: chosenRows, cellSize: cellSize, spacing: spacing)
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
