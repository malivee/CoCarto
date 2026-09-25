import Foundation

struct MicroBiomeGridGenerator: Sendable {
    func generate(from edges: CellBiomeEdges) -> MicroBiomeGrid {
        let matrix = (0..<MicroBiomeGrid.dimension).map { y in
            (0..<MicroBiomeGrid.dimension).map { x in
                edges[sector(forX: x, y: y)]
            }
        }
        return try! MicroBiomeGrid(matrix: matrix)
    }

    func sector(for position: MicroGridPosition) -> Direction {
        sector(forX: position.x, y: position.y)
    }

    private func sector(forX x: Int, y: Int) -> Direction {
        let maxIndex = MicroBiomeGrid.dimension - 1

        // Boundary samples are assigned before interior sectors. On a 6x6 grid,
        // corner microcells touch two semantic sides; row priority gives them to
        // north/south deterministically, while biome matching still uses
        // CellBiomeEdges directly instead of reading raster corners.
        if y == 0 {
            return .north
        }
        if y == maxIndex {
            return .south
        }
        if x == maxIndex {
            return .east
        }
        if x == 0 {
            return .west
        }

        // Use doubled integer cell centers around the between-cells center at 6.
        // Ties fall to the vertical sectors, making the even-sized center cross
        // deterministic without floating-point rounding.
        let center = MicroBiomeGrid.dimension
        let dx = x * 2 + 1 - center
        let dy = y * 2 + 1 - center
        if abs(dy) >= abs(dx) {
            return dy < 0 ? .north : .south
        }
        return dx < 0 ? .west : .east
    }
}
