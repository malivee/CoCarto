import Foundation

struct ConnectivityResolver: Sendable {
    func resolvedCellMap(in worldState: WorldState) -> [GridPosition: ResolvedWorldCell] {
        var cells: [GridPosition: ResolvedWorldCell] = [:]
        for piece in worldState.pieces {
            for cell in piece.resolvedCells() {
                cells[cell.globalPosition] = cell
            }
        }
        return cells
    }

    func resolvedCell(at position: GridPosition, in worldState: WorldState) -> ResolvedWorldCell? {
        resolvedCellMap(in: worldState)[position]
    }

    func canTraverse(from cell: GridPosition, toward direction: Direction, in worldState: WorldState) -> Bool {
        let cells = resolvedCellMap(in: worldState)
        guard let source = cells[cell] else {
            return false
        }

        let neighborPosition = cell + direction.gridOffset
        guard let neighbor = cells[neighborPosition] else {
            return false
        }

        return EdgeCompatibility.canConnect(source.edges[direction], neighbor.edges[direction.opposite])
    }

    func debugConnectivityDescription(for cell: GridPosition, in worldState: WorldState) -> String {
        let cells = resolvedCellMap(in: worldState)
        guard let source = cells[cell] else {
            return "Cell (\(cell.x),\(cell.y))\nEMPTY"
        }

        var lines = ["Cell (\(cell.x),\(cell.y))"]
        for direction in Direction.allCases {
            let neighborPosition = cell + direction.gridOffset
            guard let neighbor = cells[neighborPosition] else {
                lines.append("\(direction.debugLabel) -> \(source.edges[direction].rawValue.uppercased()) -> EMPTY -> BLOCKED")
                continue
            }

            let lhs = source.edges[direction]
            let rhs = neighbor.edges[direction.opposite]
            let result = EdgeCompatibility.canConnect(lhs, rhs) ? "CONNECTED" : "BLOCKED"
            lines.append("\(direction.debugLabel) -> \(lhs.rawValue.uppercased()) <-> \(rhs.rawValue.uppercased()) -> \(result)")
        }
        return lines.joined(separator: "\n")
    }
}

private extension Direction {
    var debugLabel: String {
        switch self {
        case .north:
            return "N"
        case .east:
            return "E"
        case .south:
            return "S"
        case .west:
            return "W"
        }
    }
}
