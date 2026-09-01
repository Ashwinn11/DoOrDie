import SwiftUI

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DoTheme.Color.bg.ignoresSafeArea()

                VStack(spacing: DoTheme.Space.md) {
                    Spacer()

                    // Cardless Floating Exercise SVG in Sunset Coral with soft ambient aura
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        DoTheme.Color.coral.opacity(0.18),
                                        DoTheme.Color.coral.opacity(0.04),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 110
                                )
                            )
                            .frame(width: 220, height: 220)

                        CyclingSVGView(frameImageNames: exercise.frameImageNames)
                            .foregroundStyle(DoTheme.Color.coral)
                            .frame(width: 190, height: 190)
                            .shadow(color: DoTheme.Color.coral.opacity(0.25), radius: 16, y: 6)
                    }

                    VStack(spacing: DoTheme.Space.xs) {
                        Text(exercise.name)
                            .font(DoTheme.Typography.title)
                            .foregroundStyle(DoTheme.Color.ink)
                            .multilineTextAlignment(.center)

                        HStack(spacing: DoTheme.Space.xs) {
                            Chip(text: exercise.group.label, tint: DoTheme.Color.coral.opacity(0.12), textColor: DoTheme.Color.coral)
                            Chip(text: exercise.equipment, tint: DoTheme.Color.shell, textColor: DoTheme.Color.muted)
                        }

                        Text(exercise.prescription)
                            .font(DoTheme.Typography.display(18, weight: .heavy))
                            .foregroundStyle(DoTheme.Color.coral)
                            .padding(.top, 4)
                    }

                    Spacer()
                }
                .padding(DoTheme.Space.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(DoTheme.Typography.body(16, weight: .bold))
                        .foregroundStyle(DoTheme.Color.coral)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ExerciseDetailSheet(exercise: ExerciseCatalog.all.first!)
}
