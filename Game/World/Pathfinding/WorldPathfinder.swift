struct WorldPathfinder: Sendable {
    private let connectivityResolver = ConnectivityResolver()

    func findPath(
        from start: GridPosition,
        to goal: GridPosition,
        in worldState: WorldState
    ) -> [GridPosition]? {
        findPath(fromAny: [start], toAny: [goal], in: worldState)
    }

    func findPath(
        fromAny startCells: Set<GridPosition>,
        toAny goalCells: Set<GridPosition>,
        in worldState: WorldState
    ) -> [GridPosition]? {
        let cellMap = connectivityResolver.resolvedCellMap(in: worldState)
        let starts = startCells.filter { cellMap[$0] != nil }
        let goals = goalCells.filter { cellMap[$0] != nil }

        guard !starts.isEmpty, !goals.isEmpty else {
            return nil
        }

        var frontier = Array(starts)
        var visited = Set(starts)
        var cameFrom: [GridPosition: GridPosition] = [:]

        if let immediateGoal = starts.first(where: { goals.contains($0) }) {
            return [immediateGoal]
        }

        while !frontier.isEmpty {
            let current = frontier.removeFirst()

            for direction in Direction.allCases {
                let neighbor = current + direction.gridOffset
                guard !visited.contains(neighbor),
                      cellMap[neighbor] != nil,
                      connectivityResolver.canTraverse(from: current, toward: direction, in: worldState) else {
                    continue
                }

                cameFrom[neighbor] = current
                if goals.contains(neighbor) {
                    return reconstructPath(to: neighbor, cameFrom: cameFrom)
                }

                visited.insert(neighbor)
                frontier.append(neighbor)
            }
        }

        return nil
    }

    private func reconstructPath(
        to goal: GridPosition,
        cameFrom: [GridPosition: GridPosition]
    ) -> [GridPosition] {
        var path = [goal]
        var current = goal

        while let previous = cameFrom[current] {
            path.append(previous)
            current = previous
        }

        return path.reversed()
    }
}
