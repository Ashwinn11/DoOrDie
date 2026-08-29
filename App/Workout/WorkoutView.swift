import SwiftData
import SwiftUI
import WidgetKit

struct WorkoutView: View {
    let plan: CommitmentPlan

    @Environment(\.modelContext) private var modelContext
    @Query private var routineDays: [RoutineDay]
    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]

    private var todayFocus: MuscleGroup {
        let routine = Dictionary(uniqueKeysWithValues: routineDays.map { ($0.weekday, $0.focus) })
        return routine[.today] ?? .rest
    }

    private var todayStatus: DayStatus {
        StreakEngine.status(for: .now, focus: todayFocus, checkIns: checkIns)
    }

    private var exercises: [Exercise] {
        ExerciseCatalog.exercises(for: todayFocus)
    }

    @State private var selectedExercise: Exercise?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DoTheme.Space.md) {
                    header

                    if todayFocus.demandsCheckIn {
                        ForEach(exercises) { exercise in
                            ExerciseRow(exercise: exercise)
                                .onTapGesture { selectedExercise = exercise }
                        }

                        PillButton(
                            title: todayStatus == .done ? "Done for today" : "Mark today done",
                            systemImage: todayStatus == .done ? "flame.fill" : nil,
                            style: todayStatus == .done ? .gold : .comb
                        ) {
                            guard todayStatus == .pending else { return }
                            modelContext.insert(CheckIn(date: .now, focus: todayFocus))
                            try? modelContext.save()
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                        .disabled(todayStatus == .done)
                    } else {
                        RestEmptyState()
                    }
                }
                .padding(DoTheme.Space.md)
            }
            .background(DoTheme.Color.bg.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailSheet(exercise: exercise)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DoTheme.Space.xs) {
            Text("TODAY'S WORKOUT")
                .font(DoTheme.Typography.body(12, weight: .bold))
                .foregroundStyle(DoTheme.Color.comb)
                .tracking(1.5)

            HStack {
                Text(todayFocus.label)
                    .font(DoTheme.Typography.hero)
                    .displayTracking(40)
                    .foregroundStyle(DoTheme.Color.ink)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DoTheme.Space.sm)
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: DoTheme.Space.sm) {
            Image(exercise.imageName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .padding(10)
                .foregroundStyle(DoTheme.Color.comb)
                .frame(width: 56, height: 56)
                .background(DoTheme.Color.pillGray, in: RoundedRectangle(cornerRadius: DoTheme.Radius.chip, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(DoTheme.Typography.body(16, weight: .semibold))
                    .foregroundStyle(DoTheme.Color.ink)
                Text(exercise.equipment)
                    .font(DoTheme.Typography.body(13))
                    .foregroundStyle(DoTheme.Color.muted)
            }

            Spacer()

            Text(exercise.prescription)
                .font(DoTheme.Typography.body(13, weight: .semibold))
                .foregroundStyle(DoTheme.Color.comb)
                .multilineTextAlignment(.trailing)
        }
        .padding(DoTheme.Space.sm)
        .background(DoTheme.Color.shell, in: RoundedRectangle(cornerRadius: DoTheme.Radius.tile, style: .continuous))
    }
}

private struct RestEmptyState: View {
    var body: some View {
        VStack(spacing: DoTheme.Space.sm) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 32))
                .foregroundStyle(DoTheme.Color.muted)
            Text("Rest day")
                .font(DoTheme.Typography.title)
                .foregroundStyle(DoTheme.Color.ink)
            Text("Nothing scheduled. The streak doesn't need you today.")
                .font(DoTheme.Typography.body(14))
                .foregroundStyle(DoTheme.Color.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DoTheme.Space.xl)
    }
}

#Preview {
    WorkoutView(plan: CommitmentPlan(name: "Committed", durationDays: 60, stakeCents: 2500))
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
