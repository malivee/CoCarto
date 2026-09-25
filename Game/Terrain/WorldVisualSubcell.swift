import Foundation

struct WorldVisualSubcell: Hashable, Sendable {
    static let dimension = 3

    let localPosition: GridPosition
    let sourceMicroCells: [MicroBiomeCell]

    var sourceMicroPositions: [MicroGridPosition] {
        sourceMicroCells.map(\.localPosition)
    }
}

struct WorldVisualSubcellResolver: Sendable {
    func visualSubcells(for microBiomeGrid: MicroBiomeGrid) -> [WorldVisualSubcell] {
        (0..<WorldVisualSubcell.dimension).flatMap { y in
            (0..<WorldVisualSubcell.dimension).map { x in
                let sourcePositions = [
                    MicroGridPosition(x: x * 2, y: y * 2),
                    MicroGridPosition(x: x * 2 + 1, y: y * 2),
                    MicroGridPosition(x: x * 2, y: y * 2 + 1),
                    MicroGridPosition(x: x * 2 + 1, y: y * 2 + 1)
                ]
                return WorldVisualSubcell(
                    localPosition: GridPosition(x: x, y: y),
                    sourceMicroCells: sourcePositions.map { position in
                        MicroBiomeCell(localPosition: position, biome: microBiomeGrid.biome(at: position))
                    }
                )
            }
        }
    }
}
