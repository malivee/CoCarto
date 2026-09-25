import CoreGraphics
import Foundation

struct WorldGridMapper: Sendable {
    let cellSize: CGFloat

    init(cellSize: CGFloat = 256) {
        self.cellSize = cellSize
    }

    var halfCellSize: CGFloat {
        cellSize / 2
    }

    // Grid cells are centered at integer multiples of cellSize.
    // Grid (0, 0) maps to world (0, 0); grid (1, 0) maps to (cellSize, 0).
    func worldPosition(for gridPosition: GridPosition) -> CGPoint {
        CGPoint(
            x: CGFloat(gridPosition.x) * cellSize,
            y: CGFloat(gridPosition.y) * cellSize
        )
    }

    func gridPosition(containing worldPosition: CGPoint) -> GridPosition {
        GridPosition(
            x: Int(floor((worldPosition.x + halfCellSize) / cellSize)),
            y: Int(floor((worldPosition.y + halfCellSize) / cellSize))
        )
    }

    func frame(for gridPosition: GridPosition) -> CGRect {
        let center = worldPosition(for: gridPosition)
        return CGRect(
            x: center.x - halfCellSize,
            y: center.y - halfCellSize,
            width: cellSize,
            height: cellSize
        )
    }
}
