import Foundation

struct PlacementValidator: Sendable {
    func canPlace(
        pieceID: UUID,
        at position: GridPosition,
        rotation: GridRotation,
        in worldState: WorldState
    ) -> Bool {
        guard let piece = worldState.piece(id: pieceID), piece.isMovable else {
            return false
        }

        let proposedCells = piece.occupiedCells(at: position, rotation: rotation)
        guard proposedCells.count == 4 else {
            return false
        }

        for otherPiece in worldState.pieces where otherPiece.id != pieceID {
            if !proposedCells.isDisjoint(with: otherPiece.occupiedCells()) {
                return false
            }
        }

        return true
    }
}
