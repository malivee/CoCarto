import Foundation

struct GridPosition: Hashable, Equatable, Codable, Sendable {
    var x: Int
    var y: Int

    static let zero = GridPosition(x: 0, y: 0)

    static func + (lhs: GridPosition, rhs: GridPosition) -> GridPosition {
        GridPosition(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: GridPosition, rhs: GridPosition) -> GridPosition {
        GridPosition(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
