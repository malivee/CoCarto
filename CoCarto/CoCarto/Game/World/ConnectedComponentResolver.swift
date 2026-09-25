struct ConnectedComponentResolver: Sendable {
    private let connectivityResolver = ConnectivityResolver()

    func connectedCells(startingAt start: GridPosition, in worldState: WorldState) -> Set<GridPosition> {
        let cellMap = connectivityResolver.resolvedCellMap(in: worldState)
        guard cellMap[start] != nil else {
            return []
        }

        var visited: Set<GridPosition> = [start]
        var frontier: [GridPosition] = [start]

        while let cell = frontier.popLast() {
            for direction in Direction.allCases {
                let neighbor = cell + direction.gridOffset
                guard !visited.contains(neighbor),
                      cellMap[neighbor] != nil,
                      connectivityResolver.canTraverse(from: cell, toward: direction, in: worldState) else {
                    continue
                }

                visited.insert(neighbor)
                frontier.append(neighbor)
            }
        }

        return visited
    }

    func reachableCells(from playerState: PlayerState, in worldState: WorldState) -> Set<GridPosition> {
        guard let currentCell = playerState.currentCell else {
            return []
        }

        return connectedCells(startingAt: currentCell, in: worldState)
    }
}
