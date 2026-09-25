enum GridRotation: Int, CaseIterable, Codable, Sendable {
    case degrees0 = 0
    case degrees90 = 90
    case degrees180 = 180
    case degrees270 = 270

    func rotated(_ position: GridPosition) -> GridPosition {
        switch self {
        case .degrees0:
            return position
        case .degrees90:
            return GridPosition(x: -position.y, y: position.x)
        case .degrees180:
            return GridPosition(x: -position.x, y: -position.y)
        case .degrees270:
            return GridPosition(x: position.y, y: -position.x)
        }
    }

    var nextQuarterTurn: GridRotation {
        switch self {
        case .degrees0:
            return .degrees90
        case .degrees90:
            return .degrees180
        case .degrees180:
            return .degrees270
        case .degrees270:
            return .degrees0
        }
    }

    var previousQuarterTurn: GridRotation {
        switch self {
        case .degrees0:
            return .degrees270
        case .degrees90:
            return .degrees0
        case .degrees180:
            return .degrees90
        case .degrees270:
            return .degrees180
        }
    }
}
