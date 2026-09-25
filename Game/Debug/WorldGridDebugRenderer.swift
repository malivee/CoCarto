struct WorldGridDebugRenderer: Sendable {
    func debugGridDescription(for worldState: WorldState) -> String {
        let occupiedCellsByPiece = worldState.pieces.map { piece in
            (piece: piece, cells: piece.occupiedCells())
        }

        let allCells = occupiedCellsByPiece.flatMap(\.cells)
        guard let minX = allCells.map(\.x).min(),
              let maxX = allCells.map(\.x).max(),
              let minY = allCells.map(\.y).min(),
              let maxY = allCells.map(\.y).max() else {
            return ""
        }

        var symbolsByPosition: [GridPosition: Character] = [:]
        for entry in occupiedCellsByPiece {
            for cell in entry.cells {
                symbolsByPosition[cell] = entry.piece.role.debugSymbol
            }
        }

        var rows: [String] = []
        for y in minY...maxY {
            let characters = (minX...maxX).map { x in
                symbolsByPosition[GridPosition(x: x, y: y)] ?? "."
            }
            rows.append(String(characters))
        }

        return rows.joined(separator: "\n")
    }

    func debugBiomeDescription(for cell: WorldCellDefinition) -> String {
        [
            "Legend: R rocksalt, V villageSoil, G naturalGrass, F darkGreenForest, H hillSoil",
            "Cell (\(cell.localPosition.x),\(cell.localPosition.y))",
            cell.microBiomeGrid.debugDescription()
        ].joined(separator: "\n")
    }

    func debugResolvedMicroCells(for piece: WorldPiece, limit: Int = 24) -> String {
        let cells = piece.resolvedMicroCells().sorted { lhs, rhs in
            if lhs.globalPosition.y == rhs.globalPosition.y {
                return lhs.globalPosition.x < rhs.globalPosition.x
            }
            return lhs.globalPosition.y < rhs.globalPosition.y
        }
        let lines = cells.prefix(limit).map { cell in
            "(\(cell.globalPosition.x),\(cell.globalPosition.y)) \(cell.biome.debugSymbol)"
        }
        let suffix = cells.count > limit ? "\n... \(cells.count - limit) more" : ""
        return lines.joined(separator: "\n") + suffix
    }
}

extension WorldState {
    func debugGridDescription() -> String {
        WorldGridDebugRenderer().debugGridDescription(for: self)
    }
}
