import SwiftUI

struct LegalView: View {
    enum Kind {
        case terms, privacy

        var title: String {
            switch self {
            case .terms: "Terms of Service"
            case .privacy: "Privacy Policy"
            }
        }

        var sections: [(String, String)] {
            switch self {
            case .terms:
                [
                    ("The commitment", "Do or Die tracks a workout schedule you set for yourself. Completing or missing a scheduled day is self-reported by you, inside the app."),
                    ("Stakes", "Some plans display a stake amount. No payment processor is connected yet, and nothing is charged to any payment method through this build."),
                    ("No fitness advice", "Do or Die is a scheduling and accountability tool, not a medical or fitness professional. Talk to a doctor before starting a new exercise program."),
                    ("Your data", "Your plan, routine, and check-in history are stored on this device. Deleting your data from Profile removes it permanently."),
                    ("Changes", "These terms may change as features like real stakes and subscriptions ship. Material changes will be reflected here."),
                ]
            case .privacy:
                [
                    ("What's collected", "Do or Die stores your commitment plan, weekly routine, and daily check-ins locally on your device using Apple's on-device storage."),
                    ("What's not collected", "This build does not send your workout data to any server, and does not include analytics, ads, or third-party trackers."),
                    ("Illustrations", "Exercise illustrations are loaded from a bundled open-source asset library. See Credits for attribution — no network request is made to display them."),
                    ("Deletion", "Deleting your data from Profile removes your plan, routine, and check-in history from this device immediately and permanently."),
                    ("Contact", "Questions about this policy can be directed to the app developer."),
                ]
            }
        }
    }

    let kind: Kind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DoTheme.Space.lg) {
                ForEach(kind.sections, id: \.0) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.0)
                            .font(DoTheme.Typography.display(18, weight: .bold))
                            .foregroundStyle(DoTheme.Color.ink)
                        Text(section.1)
                            .font(DoTheme.Typography.body(15))
                            .foregroundStyle(DoTheme.Color.muted)
                    }
                }

                Text("Placeholder copy for early development — not reviewed by counsel.")
                    .font(DoTheme.Typography.body(12))
                    .foregroundStyle(DoTheme.Color.muted.opacity(0.7))
                    .padding(.top, DoTheme.Space.sm)
            }
            .padding(DoTheme.Space.md)
        }
        .background(DoTheme.Color.bg.ignoresSafeArea())
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
