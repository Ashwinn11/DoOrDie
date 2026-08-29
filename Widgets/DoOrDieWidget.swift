import SwiftUI
import WidgetKit

struct DoOrDieWidget: Widget {
    let kind = "DoOrDieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoOrDieTimelineProvider()) { entry in
            DoOrDieWidgetView(entry: entry)
                .environment(\.colorScheme, .light)
        }
        .configurationDisplayName("Do or Die")
        .description("Every day of your plan, one icon at a time. Miss one and it dies.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
