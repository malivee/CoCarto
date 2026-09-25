import CoreGraphics
import Foundation

struct MapGridMapper: Sendable {
    let cellSize: CGFloat
    let origin: CGPoint

    init(cellSize: CGFloat = 88, origin: CGPoint = .zero) {
        self.cellSize = cellSize
        self.origin = origin
    }

    var halfCellSize: CGFloat {
        cellSize / 2
    }

    // Map View uses the same logical grid as WorldState; only the visual scale and origin differ.
    func mapPosition(for gridPosition: GridPosition) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(gridPosition.x) * cellSize,
            y: origin.y + CGFloat(gridPosition.y) * cellSize
        )
    }

    func gridPosition(containing point: CGPoint) -> GridPosition {
        GridPosition(
            x: Int(floor(((point.x - origin.x) + halfCellSize) / cellSize)),
            y: Int(floor(((point.y - origin.y) + halfCellSize) / cellSize))
        )
    }

    func offset(for localCell: GridPosition) -> CGPoint {
        CGPoint(
            x: CGFloat(localCell.x) * cellSize,
            y: CGFloat(localCell.y) * cellSize
        )
    }
}
