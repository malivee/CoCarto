import SpriteKit

final class WorldPieceNode: SKNode {
    let pieceID: UUID
    private let mapper: WorldGridMapper
    private let showsDebugLabels: Bool

    init(piece: WorldPiece, mapper: WorldGridMapper, showsDebugLabels: Bool) {
        self.pieceID = piece.id
        self.mapper = mapper
        self.showsDebugLabels = showsDebugLabels
        super.init()
        name = "WorldPieceNode-\(piece.role.debugSymbol)"
        apply(piece: piece)
    }

    func apply(piece: WorldPiece) {
        position = mapper.worldPosition(for: piece.gridPosition)
        zRotation = piece.rotation.radians
        rebuildCells(piece: piece)
    }

    private func rebuildCells(piece: WorldPiece) {
        removeAllChildren()
        let resolvedCellsByID = Dictionary(uniqueKeysWithValues: piece.resolvedCells().map { ($0.gridID, $0) })
        for cell in piece.cellDefinitions {
            let resolvedCell = resolvedCellsByID[cell.id]
            addChild(CellNode(
                gridID: cell.id,
                localCell: cell.localPosition,
                globalCell: resolvedCell?.globalPosition ?? piece.gridPosition + cell.localPosition,
                biomeEdges: cell.biomeEdges,
                microBiomeGrid: cell.microBiomeGrid,
                piece: piece,
                mapper: mapper,
                showsDebugLabels: showsDebugLabels
            ))
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}

private extension Set where Element == GridPosition {
    var sortedForStableRendering: [GridPosition] {
        sorted { lhs, rhs in
            if lhs.y == rhs.y {
                return lhs.x < rhs.x
            }
            return lhs.y < rhs.y
        }
    }
}
