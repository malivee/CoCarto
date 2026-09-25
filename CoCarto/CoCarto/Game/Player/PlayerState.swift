import CoreGraphics
import Foundation

struct PlayerState: Equatable {
    var currentPieceID: UUID?
    var currentCell: GridPosition?
    var localPosition: CGPoint
    var spatialState: PlayerSpatialState?

    init(
        currentPieceID: UUID?,
        currentCell: GridPosition?,
        localPosition: CGPoint,
        spatialState: PlayerSpatialState? = nil
    ) {
        self.currentPieceID = currentPieceID
        self.currentCell = currentCell
        self.localPosition = localPosition
        self.spatialState = spatialState
    }
}
