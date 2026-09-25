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

        let proposedResolvedCells = piece.resolvedCells(at: position, rotation: rotation)
        let otherCellsByPosition = Dictionary(
            uniqueKeysWithValues: worldState.pieces
                .filter { $0.id != pieceID }
                .flatMap { $0.resolvedCells() }
                .map { ($0.globalPosition, $0) }
        )
        for proposedCell in proposedResolvedCells {
            for direction in Direction.allCases {
                let neighborPosition = proposedCell.globalPosition + direction.gridOffset
                guard let neighbor = otherCellsByPosition[neighborPosition] else {
                    continue
                }

                guard microBiomeSidesMatch(proposedCell, toward: direction, neighbor) else {
                    return false
                }
            }
        }

        return true
    }

    private func microBiomeSidesMatch(
        _ first: ResolvedWorldCell,
        toward direction: Direction,
        _ second: ResolvedWorldCell
    ) -> Bool {
        edgeBiomes(of: first.microBiomeGrid, toward: direction)
            == edgeBiomes(of: second.microBiomeGrid, toward: direction.opposite)
    }

    private func edgeBiomes(of grid: MicroBiomeGrid, toward direction: Direction) -> [BiomeType] {
        let last = MicroBiomeGrid.dimension - 1
        switch direction {
        case .north:
            return (0...last).map { x in
                grid.biome(at: MicroGridPosition(x: x, y: 0))
            }
        case .east:
            return (0...last).map { y in
                grid.biome(at: MicroGridPosition(x: last, y: y))
            }
        case .south:
            return (0...last).map { x in
                grid.biome(at: MicroGridPosition(x: x, y: last))
            }
        case .west:
            return (0...last).map { y in
                grid.biome(at: MicroGridPosition(x: 0, y: y))
            }
        }
    }
}
