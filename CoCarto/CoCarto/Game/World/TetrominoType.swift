enum TetrominoType: String, CaseIterable, Codable, Sendable {
    case i
    case o
    case t
    case l
    case s
    case z

    static let requiredGridCount = 4

    // Local cells use integer coordinates relative to the piece origin.
    // The base diagrams use y increasing downward; rotation is applied around (0, 0)
    // without normalization so the pivot stays deterministic across all placements.
    var baseCells: [GridPosition] {
        switch self {
        case .i:
            return [
                GridPosition(x: 0, y: 0),
                GridPosition(x: 1, y: 0),
                GridPosition(x: 2, y: 0),
                GridPosition(x: 3, y: 0)
            ]
        case .o:
            return [
                GridPosition(x: 0, y: 0),
                GridPosition(x: 1, y: 0),
                GridPosition(x: 0, y: 1),
                GridPosition(x: 1, y: 1)
            ]
        case .t:
            return [
                GridPosition(x: -1, y: 0),
                GridPosition(x: 0, y: 0),
                GridPosition(x: 1, y: 0),
                GridPosition(x: 0, y: 1)
            ]
        case .l:
            return [
                GridPosition(x: 0, y: 0),
                GridPosition(x: 0, y: 1),
                GridPosition(x: 0, y: 2),
                GridPosition(x: 1, y: 2)
            ]
        case .s:
            return [
                GridPosition(x: 1, y: 0),
                GridPosition(x: 2, y: 0),
                GridPosition(x: 0, y: 1),
                GridPosition(x: 1, y: 1)
            ]
        case .z:
            return [
                GridPosition(x: 0, y: 0),
                GridPosition(x: 1, y: 0),
                GridPosition(x: 1, y: 1),
                GridPosition(x: 2, y: 1)
            ]
        }
    }

    func rotatedCells(rotation: GridRotation) -> [GridPosition] {
        baseCells.map { rotation.rotated($0) }
    }
}

func rotatedCells(for type: TetrominoType, rotation: GridRotation) -> [GridPosition] {
    type.rotatedCells(rotation: rotation)
}
