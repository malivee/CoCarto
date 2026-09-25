import Foundation

struct WorldPiece: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let type: TetrominoType
    let role: PieceRole
    let cellDefinitions: [WorldCellDefinition]

    var gridPosition: GridPosition
    var rotation: GridRotation
    var isMovable: Bool

    init(
        id: UUID,
        type: TetrominoType,
        role: PieceRole,
        gridPosition: GridPosition,
        rotation: GridRotation,
        isMovable: Bool,
        cellDefinitions: [WorldCellDefinition]? = nil
    ) {
        self.id = id
        self.type = type
        self.role = role
        self.gridPosition = gridPosition
        self.rotation = rotation
        self.isMovable = isMovable
        let definitions = cellDefinitions ?? type.baseCells.enumerated().map { index, position in
            WorldCellDefinition(id: GridID(Self.defaultGridID(for: index)), localPosition: position, edges: .open)
        }
        precondition(definitions.count == TetrominoType.requiredGridCount, "A tetromino must contain exactly \(TetrominoType.requiredGridCount) grid definitions.")
        self.cellDefinitions = definitions
    }

    func localCells() -> Set<GridPosition> {
        Set(type.rotatedCells(rotation: rotation))
    }

    func occupiedCells() -> Set<GridPosition> {
        Set(type.rotatedCells(rotation: rotation).map { gridPosition + $0 })
    }

    func occupiedCells(at position: GridPosition, rotation proposedRotation: GridRotation) -> Set<GridPosition> {
        Set(type.rotatedCells(rotation: proposedRotation).map { position + $0 })
    }

    func resolvedCells() -> [ResolvedWorldCell] {
        let definitionsByLocalPosition = Dictionary(uniqueKeysWithValues: cellDefinitions.map { ($0.localPosition, $0) })

        return type.baseCells.map { baseCell in
            let definition = definitionsByLocalPosition[baseCell] ?? WorldCellDefinition(localPosition: baseCell, edges: .open)
            let rotatedLocal = rotation.rotated(baseCell)
            return ResolvedWorldCell(
                pieceID: id,
                gridID: definition.id,
                sourceLocalPosition: definition.localPosition,
                localPosition: rotatedLocal,
                globalPosition: gridPosition + rotatedLocal,
                edges: definition.edges.rotated(by: rotation),
                localBiomeEdges: definition.biomeEdges,
                biomeEdges: definition.biomeEdges.rotated(by: rotation),
                sourceMicroBiomeGrid: definition.microBiomeGrid,
                microBiomeGrid: definition.microBiomeGrid.rotated(by: rotation)
            )
        }
    }

    func resolvedCells(at position: GridPosition, rotation proposedRotation: GridRotation) -> [ResolvedWorldCell] {
        let definitionsByLocalPosition = Dictionary(uniqueKeysWithValues: cellDefinitions.map { ($0.localPosition, $0) })

        return type.baseCells.map { baseCell in
            let definition = definitionsByLocalPosition[baseCell] ?? WorldCellDefinition(localPosition: baseCell, edges: .open)
            let rotatedLocal = proposedRotation.rotated(baseCell)
            return ResolvedWorldCell(
                pieceID: id,
                gridID: definition.id,
                sourceLocalPosition: definition.localPosition,
                localPosition: rotatedLocal,
                globalPosition: position + rotatedLocal,
                edges: definition.edges.rotated(by: proposedRotation),
                localBiomeEdges: definition.biomeEdges,
                biomeEdges: definition.biomeEdges.rotated(by: proposedRotation),
                sourceMicroBiomeGrid: definition.microBiomeGrid,
                microBiomeGrid: definition.microBiomeGrid.rotated(by: proposedRotation)
            )
        }
    }

    func resolvedBiome(
        for definition: WorldCellDefinition,
        toward worldDirection: Direction,
        rotation proposedRotation: GridRotation? = nil
    ) -> BiomeType {
        definition.biomeEdges.rotated(by: proposedRotation ?? rotation)[worldDirection]
    }

    private static func defaultGridID(for index: Int) -> String {
        let scalar = UnicodeScalar(65 + index)!
        return String(Character(scalar))
    }
}
