import CoreGraphics

struct GridBounds: Equatable, Sendable {
    let minX: Int
    let maxX: Int
    let minY: Int
    let maxY: Int

    var widthInCells: Int {
        maxX - minX + 1
    }

    var heightInCells: Int {
        maxY - minY + 1
    }

    var centerGridPosition: CGPoint {
        CGPoint(
            x: (CGFloat(minX) + CGFloat(maxX)) / 2,
            y: (CGFloat(minY) + CGFloat(maxY)) / 2
        )
    }

    init?(occupiedCells: Set<GridPosition>) {
        guard let minX = occupiedCells.map(\.x).min(),
              let maxX = occupiedCells.map(\.x).max(),
              let minY = occupiedCells.map(\.y).min(),
              let maxY = occupiedCells.map(\.y).max() else {
            return nil
        }

        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    init?(worldState: WorldState) {
        self.init(occupiedCells: Set(worldState.pieces.flatMap { $0.occupiedCells() }))
    }
}
