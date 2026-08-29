import SwiftData
import SwiftUI

struct EditWeekSheet: View {
    let routineDays: [RoutineDay]
    @Environment(\.dismiss) private var dismiss

    private var sortedDays: [RoutineDay] {
        routineDays.sorted { $0.weekdayRaw < $1.weekdayRaw }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DoTheme.Space.sm) {
                    ForEach(sortedDays) { day in
                        FocusPickerRow(
                            label: day.weekday.short,
                            focus: day.focus,
                            onSelect: { day.focus = $0 }
                        )
                    }
                }
                .padding(DoTheme.Space.md)
            }
            .background(DoTheme.Color.bg.ignoresSafeArea())
            .navigationTitle("Your Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
