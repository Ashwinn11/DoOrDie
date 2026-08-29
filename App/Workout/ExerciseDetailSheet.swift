import SwiftUI

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                DarkCard(padding: DoTheme.Space.lg) {
                    VStack(spacing: DoTheme.Space.md) {
                        CyclingSVGView(frameImageNames: exercise.frameImageNames)
                            .foregroundStyle(DoTheme.Color.comb)
                            .frame(width: 180, height: 180)

                        Text(exercise.name)
                            .font(DoTheme.Typography.title)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        HStack(spacing: DoTheme.Space.xs) {
                            Chip(text: exercise.group.label, tint: DoTheme.Color.comb, textColor: .white)
                            Chip(text: exercise.equipment, tint: DoTheme.Color.pillGray)
                        }

                        Text(exercise.prescription)
                            .font(DoTheme.Typography.body(15, weight: .semibold))
                            .foregroundStyle(DoTheme.Color.gold)
                    }
                }

                Spacer()
            }
            .padding(DoTheme.Space.lg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ExerciseDetailSheet(exercise: ExerciseCatalog.all.first!)
}
