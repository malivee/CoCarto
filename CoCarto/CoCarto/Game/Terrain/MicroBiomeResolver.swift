import Foundation

struct MicroBiomeResolver: Sendable {
    func resolvedMicroCells(for piece: WorldPiece) -> [ResolvedMicroBiomeCell] {
        resolvedMicroCells(for: piece, at: piece.gridPosition, rotation: piece.rotation)
    }

    func resolvedMicroCells(
        for piece: WorldPiece,
        at position: GridPosition,
        rotation: GridRotation
    ) -> [ResolvedMicroBiomeCell] {
        let definitionsByLocalPosition = Dictionary(uniqueKeysWithValues: piece.cellDefinitions.map { ($0.localPosition, $0) })

        return piece.type.baseCells.flatMap { baseCell -> [ResolvedMicroBiomeCell] in
            let definition = definitionsByLocalPosition[baseCell] ?? WorldCellDefinition(localPosition: baseCell, edges: .open)
            let resolvedLargeCellOffset = rotation.rotated(baseCell)
            let largeCellPosition = position + resolvedLargeCellOffset

            return definition.microBiomeGrid.cells().map { microCell in
                let resolvedMicroPosition = microCell.localPosition.rotated(by: rotation)
                return ResolvedMicroBiomeCell(
                    globalPosition: GlobalMicroPosition(
                        largeCellPosition: largeCellPosition,
                        localMicroPosition: resolvedMicroPosition
                    ),
                    biome: microCell.biome,
                    pieceID: piece.id,
                    gridID: definition.id,
                    largeCellPosition: largeCellPosition,
                    localMicroPosition: microCell.localPosition,
                    resolvedMicroPosition: resolvedMicroPosition
                )
            }
        }
    }

    func microTerrainMap(for worldState: WorldState) -> [GlobalMicroPosition: ResolvedMicroBiomeCell] {
        var resolvedCells: [GlobalMicroPosition: ResolvedMicroBiomeCell] = [:]
        for piece in worldState.pieces {
            for cell in resolvedMicroCells(for: piece) {
                assert(resolvedCells[cell.globalPosition] == nil, "Duplicate resolved micro biome at \(cell.globalPosition).")
                resolvedCells[cell.globalPosition] = cell
            }
        }
        return resolvedCells
    }

    func biome(at globalMicroPosition: GlobalMicroPosition, in worldState: WorldState) -> BiomeType? {
        microTerrainMap(for: worldState)[globalMicroPosition]?.biome
    }
}

extension WorldPiece {
    func resolvedMicroCells() -> [ResolvedMicroBiomeCell] {
        MicroBiomeResolver().resolvedMicroCells(for: self)
    }

    func resolvedMicroCells(at position: GridPosition, rotation proposedRotation: GridRotation) -> [ResolvedMicroBiomeCell] {
        MicroBiomeResolver().resolvedMicroCells(for: self, at: position, rotation: proposedRotation)
    }

    func debugMicroBiomeDescription(forLocalCell localCell: GridPosition) -> String? {
        cellDefinitions.first(where: { $0.localPosition == localCell })?.microBiomeGrid.debugDescription()
    }
}

extension WorldState {
    func microTerrainMap() -> [GlobalMicroPosition: ResolvedMicroBiomeCell] {
        MicroBiomeResolver().microTerrainMap(for: self)
    }

    func biome(at globalMicroPosition: GlobalMicroPosition) -> BiomeType? {
        MicroBiomeResolver().biome(at: globalMicroPosition, in: self)
    }
}
