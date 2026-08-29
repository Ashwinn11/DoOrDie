import Foundation

/// Matches Foundation's Calendar.component(.weekday: ...) numbering (Sun = 1).
enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var short: String {
        switch self {
        case .sunday: "SUN"
        case .monday: "MON"
        case .tuesday: "TUE"
        case .wednesday: "WED"
        case .thursday: "THU"
        case .friday: "FRI"
        case .saturday: "SAT"
        }
    }

    var full: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }

    static var today: Weekday {
        Weekday(rawValue: Calendar.current.component(.weekday, from: .now)) ?? .sunday
    }
}
