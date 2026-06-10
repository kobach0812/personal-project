import SwiftUI

/// Spacing scale — a 4-pt grid (design guide Tier 1.2). Use for padding, gaps, margins.
enum ThemeSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// Corner-radius scale (design guide Tier 1.3).
enum ThemeRadius {
    /// Pills, small badges.
    static let sm: CGFloat = 4
    /// Chips, status indicators.
    static let md: CGFloat = 8
    /// Cards, buttons.
    static let lg: CGFloat = 12
    /// Sheets, modals, hero cards.
    static let xl: CGFloat = 16
}

/// Elevation system — three levels (design guide Tier 1.4).
enum ThemeElevation {
    case low   // pressed states
    case mid   // cards, default
    case high  // sheets, modals

    var radius: CGFloat {
        switch self {
        case .low:  return 4
        case .mid:  return 12
        case .high: return 24
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .low:  return 2
        case .mid:  return 4
        case .high: return 8
        }
    }

    var opacity: Double {
        switch self {
        case .low:  return 0.04
        case .mid:  return 0.06
        case .high: return 0.10
        }
    }
}

extension View {
    /// Applies a token elevation shadow.
    func themeShadow(_ level: ThemeElevation) -> some View {
        shadow(color: .black.opacity(level.opacity), radius: level.radius, x: 0, y: level.yOffset)
    }
}
