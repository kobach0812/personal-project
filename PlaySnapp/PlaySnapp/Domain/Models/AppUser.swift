import Foundation

enum Sport: String, CaseIterable, Codable, Identifiable, Sendable {
    case football
    case basketball
    case tennis
    case padel
    case badminton
    case running
    case volleyball

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .football:
            return "Football"
        case .basketball:
            return "Basketball"
        case .tennis:
            return "Tennis"
        case .padel:
            return "Padel"
        case .badminton:
            return "Badminton"
        case .running:
            return "Running"
        case .volleyball:
            return "Volleyball"
        }
    }
}

struct AppUser: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var primarySport: Sport
    var avatarURL: URL?
    var squadID: String?
    let createdAt: Date
    var updatedAt: Date
}
