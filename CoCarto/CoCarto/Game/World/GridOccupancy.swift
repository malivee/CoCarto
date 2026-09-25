import Foundation

struct GridOccupancy: Equatable, Sendable {
    private let occupantByPosition: [GridPosition: UUID]
    private let positionsByPieceID: [UUID: Set<GridPosition>]

    init(worldState: WorldState) {
        var occupantByPosition: [GridPosition: UUID] = [:]
        var positionsByPieceID: [UUID: Set<GridPosition>] = [:]

        for piece in worldState.pieces {
            let cells = piece.occupiedCells()
            positionsByPieceID[piece.id] = cells

            for cell in cells {
                occupantByPosition[cell] = piece.id
            }
        }

        self.occupantByPosition = occupantByPosition
        self.positionsByPieceID = positionsByPieceID
    }

    func pieceID(at position: GridPosition) -> UUID? {
        occupantByPosition[position]
    }

    func isCellFree(_ position: GridPosition) -> Bool {
        pieceID(at: position) == nil
    }

    func occupiedCells(for pieceID: UUID) -> Set<GridPosition> {
        positionsByPieceID[pieceID, default: []]
    }
}
