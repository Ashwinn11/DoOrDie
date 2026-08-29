import SwiftUI

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DoTheme.Space.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Exercise illustrations")
                        .font(DoTheme.Typography.display(18, weight: .bold))
                        .foregroundStyle(DoTheme.Color.ink)
                    Text("Illustrations by Bryl Lim (bryllim.com), from the open-source workout-guide library, licensed CC BY-SA 4.0. Pose data derived from the Everkinetic project, also CC BY-SA 4.0.")
                        .font(DoTheme.Typography.body(15))
                        .foregroundStyle(DoTheme.Color.muted)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Typeface")
                        .font(DoTheme.Typography.display(18, weight: .bold))
                        .foregroundStyle(DoTheme.Color.ink)
                    Text("Display type uses San Francisco Rounded, Apple's system rounded typeface.")
                        .font(DoTheme.Typography.body(15))
                        .foregroundStyle(DoTheme.Color.muted)
                }
            }
            .padding(DoTheme.Space.md)
        }
        .background(DoTheme.Color.bg.ignoresSafeArea())
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}
