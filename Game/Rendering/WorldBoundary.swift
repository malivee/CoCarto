import CoreGraphics

enum WorldBoundaryType: Hashable, Sendable {
    case outerVoid
    case blockedEdge
    case forest
    case cliff
}

struct WorldBoundary: Hashable, Sendable {
    let cell: GridPosition
    let direction: Direction
    let type: WorldBoundaryType

    init(cell: GridPosition, direction: Direction, type: WorldBoundaryType = .outerVoid) {
        self.cell = cell
        self.direction = direction
        self.type = type
    }
}

struct WorldBoundaryGenerator: Sendable {
    private let connectivityResolver = ConnectivityResolver()

    func boundaries(for occupiedCells: Set<GridPosition>) -> Set<WorldBoundary> {
        var boundaries: Set<WorldBoundary> = []

        for cell in occupiedCells {
            for direction in Direction.allCases {
                let neighbor = cell + direction.gridOffset
                if !occupiedCells.contains(neighbor) {
                    boundaries.insert(WorldBoundary(cell: cell, direction: direction, type: .outerVoid))
                }
            }
        }

        return boundaries
    }

    func boundaries(for worldState: WorldState) -> Set<WorldBoundary> {
        let cells = connectivityResolver.resolvedCellMap(in: worldState)
        var boundaries: Set<WorldBoundary> = []

        for (position, cell) in cells {
            for direction in Direction.allCases {
                let neighborPosition = position + direction.gridOffset
                guard let neighbor = cells[neighborPosition] else {
                    boundaries.insert(WorldBoundary(cell: position, direction: direction, type: .outerVoid))
                    continue
                }

                guard shouldCreateSharedBoundary(from: position, to: neighborPosition) else {
                    continue
                }

                let lhs = cell.edges[direction]
                let rhs = neighbor.edges[direction.opposite]
                if !EdgeCompatibility.canConnect(lhs, rhs) {
                    boundaries.insert(WorldBoundary(
                        cell: position,
                        direction: direction,
                        type: boundaryType(lhs: lhs, rhs: rhs)
                    ))
                }
            }
        }

        return boundaries
    }

    private func shouldCreateSharedBoundary(from lhs: GridPosition, to rhs: GridPosition) -> Bool {
        if lhs.x == rhs.x {
            return lhs.y < rhs.y
        }
        return lhs.x < rhs.x
    }

    private func boundaryType(lhs: EdgeType, rhs: EdgeType) -> WorldBoundaryType {
        if lhs == .cliff || rhs == .cliff {
            return .cliff
        }

        if lhs == .forest || rhs == .forest {
            return .forest
        }

        return .blockedEdge
    }
}

extension Direction {
    var gridOffset: GridPosition {
        switch self {
        case .north:
            return GridPosition(x: 0, y: 1)
        case .east:
            return GridPosition(x: 1, y: 0)
        case .south:
            return GridPosition(x: 0, y: -1)
        case .west:
            return GridPosition(x: -1, y: 0)
        }
    }
}
