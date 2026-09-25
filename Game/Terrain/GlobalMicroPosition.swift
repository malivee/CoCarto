import Foundation

struct GlobalMicroPosition: Hashable, Codable, Sendable {
    let x: Int
    let y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    init(largeCellPosition: GridPosition, localMicroPosition: MicroGridPosition) {
        self.x = largeCellPosition.x * MicroBiomeGrid.dimension + localMicroPosition.x
        self.y = largeCellPosition.y * MicroBiomeGrid.dimension + localMicroPosition.y
    }

    init(piecePosition: GridPosition, localMicroOffset: GridPosition) {
        self.x = piecePosition.x * MicroBiomeGrid.dimension + localMicroOffset.x
        self.y = piecePosition.y * MicroBiomeGrid.dimension + localMicroOffset.y
    }
}
