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
    @State private var showBurst = false
    @State private var particles = makeWorkoutParticles()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DoTheme.Space.md) {
                    header

                    if todayFocus.demandsCheckIn {
                        ForEach(exercises) { exercise in
                            ExerciseRow(exercise: exercise) {
                                HapticEngine.impact(.light)
                                selectedExercise = exercise
                            }
                        }

                        ZStack {
                            PillButton(
                                title: todayStatus == .done ? "Done for today" : "Mark today done",
                                systemImage: todayStatus == .done ? "flame.fill" : nil,
                                style: todayStatus == .done ? .gold : .comb
                            ) {
                                handleCheckIn()
                            }
                            .disabled(todayStatus == .done)

                            if showBurst {
                                ForEach(particles) { p in
                                    WorkoutParticleView(particle: p)
                                }
                            }
                        }
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

    private func handleCheckIn() {
        guard todayStatus == .pending else { return }
        HapticEngine.notification(.success)
        triggerBurst()
        modelContext.insert(CheckIn(date: .now, focus: todayFocus))
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func triggerBurst() {
        particles = makeWorkoutParticles()
        showBurst = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { showBurst = false }
    }
}

// MARK: - Particles

private struct WorkoutParticle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let color: Color
    let delay: Double
}

private func makeWorkoutParticles() -> [WorkoutParticle] {
    let colors: [Color] = [DoTheme.Color.gold, DoTheme.Color.comb, .white, DoTheme.Color.gold]
    return (0..<20).map { i in
        WorkoutParticle(
            angle: Double(i) * (.pi * 2 / 20) + Double.random(in: -0.15...0.15),
            distance: CGFloat.random(in: 55...130),
            size: CGFloat.random(in: 5...10),
            color: colors[i % colors.count],
            delay: Double.random(in: 0...0.08)
        )
    }
}

private struct WorkoutParticleView: View {
    let particle: WorkoutParticle

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let dx = cos(particle.angle) * particle.distance
                let dy = sin(particle.angle) * particle.distance
                withAnimation(.easeOut(duration: 0.55).delay(particle.delay)) {
                    offset = CGSize(width: dx, height: dy)
                    opacity = 0
                }
                withAnimation(.easeIn(duration: 0.08).delay(particle.delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - ExerciseRow

private struct ExerciseRow: View {
    let exercise: Exercise
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .buttonStyle(RowButtonStyle())
    }
}

/// Scale-only press style for list rows — identical feel to PressableButtonStyle
/// but as a standalone type so it can be applied to non-pill shapes.
private struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DoTheme.Motion.snappy, value: configuration.isPressed)
    }
}

// MARK: - RestEmptyState

private struct RestEmptyState: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: DoTheme.Space.sm) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 32))
                .foregroundStyle(DoTheme.Color.muted)
                .scaleEffect(appeared ? 1 : 0.7)
                .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1), value: appeared)
            Text("Rest day")
                .font(DoTheme.Typography.title)
                .foregroundStyle(DoTheme.Color.ink)
                .opacity(appeared ? 1 : 0)
                .animation(DoTheme.Motion.easeOut.delay(0.15), value: appeared)
            Text("Nothing scheduled. The streak doesn't need you today.")
                .font(DoTheme.Typography.body(14))
                .foregroundStyle(DoTheme.Color.muted)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .animation(DoTheme.Motion.easeOut.delay(0.2), value: appeared)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DoTheme.Space.xl)
        .onAppear { appeared = true }
    }
}

#Preview {
    WorkoutView(plan: CommitmentPlan(name: "Committed", durationDays: 60, stakeCents: 2500))
        .modelContainer(for: [CommitmentPlan.self, RoutineDay.self, CheckIn.self], inMemory: true)
}
