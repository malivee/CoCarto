import Foundation

struct MicroBiomeGridGenerator: Sendable {
    func generate(from edges: CellBiomeEdges) -> MicroBiomeGrid {
        if let centeredGrid = generateCenteredSplit(from: edges) {
            return centeredGrid
        }

        let matrix = (0..<MicroBiomeGrid.dimension).map { y in
            (0..<MicroBiomeGrid.dimension).map { x in
                edges[sector(forX: x, y: y)]
            }
        }
        var grid = try! MicroBiomeGrid(matrix: matrix)
        let last = MicroBiomeGrid.dimension - 1
        for position in MicroGridPosition.allPositions {
            let x = position.x
            let y = position.y
            guard x == y || x + y == last else { continue }
            let isTop = y < MicroBiomeGrid.dimension / 2
            let isLeft = x < MicroBiomeGrid.dimension / 2
            let verticalBiome = edges[isTop ? .north : .south]
            let horizontalBiome = edges[isLeft ? .west : .east]
            guard verticalBiome != horizontalBiome else { continue }
            let corner: MicroBiomeSplit.Corner
            if isTop {
                corner = isLeft ? .topRight : .topLeft
            } else {
                corner = isLeft ? .bottomRight : .bottomLeft
            }
            grid.setSplit(MicroBiomeSplit(
                primaryBiome: verticalBiome,
                secondaryBiome: horizontalBiome,
                primaryCorner: corner
            ), at: position)
        }
        return grid
    }

    func sector(for position: MicroGridPosition) -> Direction {
        sector(forX: position.x, y: position.y)
    }

    private func generateCenteredSplit(from edges: CellBiomeEdges) -> MicroBiomeGrid? {
        let sideBiomes: [(direction: Direction, biome: BiomeType)] = [
            (.north, edges.north),
            (.east, edges.east),
            (.south, edges.south),
            (.west, edges.west)
        ]
        let uniqueBiomes = sideBiomes.reduce(into: [BiomeType]()) { result, side in
            if !result.contains(side.biome) {
                result.append(side.biome)
            }
        }

        guard uniqueBiomes.count > 1 else {
            return MicroBiomeGrid.uniform(edges.north)
        }
        guard uniqueBiomes.count == 2 else {
            return nil
        }

        let firstBiome = uniqueBiomes[0]
        let secondBiome = uniqueBiomes[1]
        let firstDirections = sideBiomes.compactMap { $0.biome == firstBiome ? $0.direction : nil }
        let secondDirections = sideBiomes.compactMap { $0.biome == secondBiome ? $0.direction : nil }

        if firstDirections.count == 1 {
            return diagonalGrid(
                majorityBiome: secondBiome,
                minorityBiome: firstBiome,
                minorityDirection: firstDirections[0]
            )
        }
        if secondDirections.count == 1 {
            return diagonalGrid(
                majorityBiome: firstBiome,
                minorityBiome: secondBiome,
                minorityDirection: secondDirections[0]
            )
        }
        if firstDirections.count == 2, secondDirections.count == 2 {
            if areAdjacent(firstDirections), areAdjacent(secondDirections) {
                return centeredDiagonalGrid(
                    firstBiome: firstBiome,
                    firstDirections: firstDirections,
                    secondBiome: secondBiome
                )
            }
        }

        return nil
    }

    private func diagonalGrid(
        majorityBiome: BiomeType,
        minorityBiome: BiomeType,
        minorityDirection: Direction
    ) -> MicroBiomeGrid {
        let corner: MicroBiomeSplit.Corner
        switch minorityDirection {
        case .north, .west: corner = .topLeft
        case .east, .south: corner = .bottomRight
        }
        return .diagonal(primaryBiome: minorityBiome, secondaryBiome: majorityBiome, primaryCorner: corner)
    }

    private func centeredDiagonalGrid(
        firstBiome: BiomeType,
        firstDirections: [Direction],
        secondBiome: BiomeType
    ) -> MicroBiomeGrid {
        let corner: MicroBiomeSplit.Corner
        if contains(firstDirections, .north) && contains(firstDirections, .east) {
            corner = .topRight
        } else if contains(firstDirections, .east) && contains(firstDirections, .south) {
            corner = .bottomRight
        } else if contains(firstDirections, .south) && contains(firstDirections, .west) {
            corner = .bottomLeft
        } else {
            corner = .topLeft
        }
        return .diagonal(primaryBiome: firstBiome, secondaryBiome: secondBiome, primaryCorner: corner)
    }

    private func areAdjacent(_ directions: [Direction]) -> Bool {
        guard directions.count == 2 else {
            return false
        }
        let first = directions[0]
        let second = directions[1]
        switch (first, second) {
        case (.north, .east), (.east, .north),
             (.east, .south), (.south, .east),
             (.south, .west), (.west, .south),
             (.west, .north), (.north, .west):
            return true
        default:
            return false
        }
    }

    private func contains(_ directions: [Direction], _ direction: Direction) -> Bool {
        directions.contains { $0 == direction }
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
