import Foundation

/// Sourced from @bryllim/workout-guide (MIT code / CC BY-SA 4.0 art,
/// Everkinetic-derived). See Profile > Credits for attribution.
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let slug: String
    let name: String
    let group: MuscleGroup
    let equipment: String
    let exerciseType: String
    let frameImageNames: [String]

    var imageName: String { frameImageNames.first ?? "" }

    var prescription: String {
        switch exerciseType {
        case "duration": "3 rounds x 45s"
        case "distance_duration": "20 min"
        default: "3 sets x 10 reps"
        }
    }
}

enum ExerciseCatalog {
    static let all: [Exercise] = {
        guard let url = Bundle.main.url(forResource: "Exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let exercises = try? JSONDecoder().decode([Exercise].self, from: data)
        else { return [] }
        return exercises
    }()

    static func exercises(for group: MuscleGroup) -> [Exercise] {
        all.filter { $0.group == group }
    }
}
