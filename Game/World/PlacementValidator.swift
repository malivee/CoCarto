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

        return BuildingPlacementValidator().supportsExistingObjects(
            in: worldState.previewingPiece(id: pieceID, at: position, rotation: rotation)
        )
    }

    func mismatchedEdgeDirections(
        pieceID: UUID,
        at position: GridPosition,
        rotation: GridRotation,
        in worldState: WorldState
    ) -> [GridPosition: [Direction]] {
        guard let piece = worldState.piece(id: pieceID) else { return [:] }
        let proposedResolvedCells = piece.resolvedCells(at: position, rotation: rotation)
        let otherCellsByPosition = Dictionary(
            uniqueKeysWithValues: worldState.pieces
                .filter { $0.id != pieceID }
                .flatMap { $0.resolvedCells() }
                .map { ($0.globalPosition, $0) }
        )

        var mismatches: [GridPosition: [Direction]] = [:]
        for proposedCell in proposedResolvedCells {
            for direction in Direction.allCases {
                let neighborPosition = proposedCell.globalPosition + direction.gridOffset
                guard let neighbor = otherCellsByPosition[neighborPosition],
                      !microBiomeSidesMatch(proposedCell, toward: direction, neighbor) else {
                    continue
                }

                let localDirection = Direction.allCases.first { $0.rotated(by: rotation) == direction } ?? direction
                if mismatches[proposedCell.sourceLocalPosition, default: []].contains(localDirection) == false {
                    mismatches[proposedCell.sourceLocalPosition, default: []].append(localDirection)
                }
            }
        }
        return mismatches
    }

    private func microBiomeSidesMatch(
        _ first: ResolvedWorldCell,
        toward direction: Direction,
        _ second: ResolvedWorldCell
    ) -> Bool {
        zip(
            edgeBiomeOptions(of: first.microBiomeGrid, toward: direction),
            edgeBiomeOptions(of: second.microBiomeGrid, toward: direction.opposite)
        ).allSatisfy { !$0.isDisjoint(with: $1) }
    }

    private func edgeBiomeOptions(of grid: MicroBiomeGrid, toward direction: Direction) -> [Set<BiomeType>] {
        let last = MicroBiomeGrid.dimension - 1
        let positions: [MicroGridPosition]
        switch direction {
        case .north:
            positions = (0...last).map { MicroGridPosition(x: $0, y: 0) }
        case .east:
            positions = (0...last).map { MicroGridPosition(x: last, y: $0) }
        case .south:
            positions = (0...last).map { MicroGridPosition(x: $0, y: last) }
        case .west:
            positions = (0...last).map { MicroGridPosition(x: 0, y: $0) }
        }
        return positions.map { position in
            if let biome = grid.biome(at: position) {
                return [biome]
            }
            if let split = grid.split(at: position) {
                return [split.primaryBiome, split.secondaryBiome]
            }
            return []
        }
    }
}
