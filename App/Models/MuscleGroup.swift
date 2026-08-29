import SwiftUI

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest, back, legs, shoulders, arms, core, cardio, rest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .legs: "Legs"
        case .shoulders: "Shoulders"
        case .arms: "Arms"
        case .core: "Core"
        case .cardio: "Cardio"
        case .rest: "Rest"
        }
    }

    var systemImage: String {
        switch self {
        case .chest: "figure.strengthtraining.traditional"
        case .back: "figure.rower"
        case .legs: "figure.step.training"
        case .shoulders: "figure.arms.open"
        case .arms: "dumbbell.fill"
        case .core: "figure.core.training"
        case .cardio: "figure.run"
        case .rest: "moon.zzz.fill"
        }
    }

    /// Rest days don't require a check-in to keep the streak alive.
    var demandsCheckIn: Bool { self != .rest }

    var tint: Color {
        self == .rest ? DoTheme.Color.pillGray : DoTheme.Color.comb
    }
}
