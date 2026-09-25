import CoreGraphics
import Foundation

struct PiecePlacementSnapshot: Equatable, Sendable {
    let gridPosition: GridPosition
    let rotation: GridRotation
}

struct PiecePlacementPreview: Equatable, Sendable {
    let pieceID: UUID
    let originalPlacement: PiecePlacementSnapshot
    var proposedPosition: GridPosition
    var proposedRotation: GridRotation
    var visualPosition: CGPoint
    var isValid: Bool
}
