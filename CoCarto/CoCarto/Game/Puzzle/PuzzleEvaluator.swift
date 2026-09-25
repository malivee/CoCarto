struct PuzzleEvaluationResult: Equatable, Sendable {
    let isSatisfied: Bool
    let startCells: Set<GridPosition>
    let throughCells: Set<GridPosition>
    let goalCells: Set<GridPosition>
    let reachableFromStart: Set<GridPosition>
    let reachableFromGoal: Set<GridPosition>
    let bridgeCells: Set<GridPosition>
}

struct PuzzleEvaluator: Sendable {
    private let roleCellResolver = WorldRoleCellResolver()
    private let componentResolver = ConnectedComponentResolver()

    func evaluate(definition: PuzzleDefinition, worldState: WorldState) -> Bool {
        evaluationResult(definition: definition, worldState: worldState).isSatisfied
    }

    func evaluationResult(definition: PuzzleDefinition, worldState: WorldState) -> PuzzleEvaluationResult {
        switch definition.condition {
        case .routeThroughPiece(let startRole, let throughRole, let goalRole):
            return evaluateRouteThroughPiece(
                from: startRole,
                through: throughRole,
                to: goalRole,
                in: worldState
            )
        }
    }

    func debugPuzzleEvaluation(definition: PuzzleDefinition, worldState: WorldState) -> String {
        let result = evaluationResult(definition: definition, worldState: worldState)
        let bridgeDescription: String
        if result.bridgeCells.isEmpty {
            bridgeDescription = "none"
        } else {
            bridgeDescription = result.bridgeCells
                .sortedForDebug
                .map { "(\($0.x),\($0.y))" }
                .joined(separator: ", ")
        }

        return [
            "Puzzle: \(definition.debugName)",
            "Start cells: \(result.startCells.count)",
            "Through cells: \(result.throughCells.count)",
            "Goal cells: \(result.goalCells.count)",
            "Reachable from start: \(result.reachableFromStart.count)",
            "Reachable from goal: \(result.reachableFromGoal.count)",
            "Bridge cells: \(bridgeDescription)",
            "RESULT: \(result.isSatisfied ? "SOLVED" : "UNSOLVED")"
        ].joined(separator: "\n")
    }

    private func evaluateRouteThroughPiece(
        from startRole: PieceRole,
        through throughRole: PieceRole,
        to goalRole: PieceRole,
        in worldState: WorldState
    ) -> PuzzleEvaluationResult {
        let startCells = roleCellResolver.cells(for: startRole, in: worldState)
        let throughCells = roleCellResolver.cells(for: throughRole, in: worldState)
        let goalCells = roleCellResolver.cells(for: goalRole, in: worldState)

        let reachableFromStart = reachableCells(fromAny: startCells, in: worldState)
        let reachableFromGoal = reachableCells(fromAny: goalCells, in: worldState)
        let bridgeCells = reachableFromStart
            .intersection(reachableFromGoal)
            .intersection(throughCells)

        return PuzzleEvaluationResult(
            isSatisfied: !bridgeCells.isEmpty,
            startCells: startCells,
            throughCells: throughCells,
            goalCells: goalCells,
            reachableFromStart: reachableFromStart,
            reachableFromGoal: reachableFromGoal,
            bridgeCells: bridgeCells
        )
    }

    private func reachableCells(fromAny cells: Set<GridPosition>, in worldState: WorldState) -> Set<GridPosition> {
        cells.reduce(into: Set<GridPosition>()) { result, cell in
            result.formUnion(componentResolver.connectedCells(startingAt: cell, in: worldState))
        }
    }
}

private extension Set where Element == GridPosition {
    var sortedForDebug: [GridPosition] {
        sorted { lhs, rhs in
            if lhs.y == rhs.y {
                return lhs.x < rhs.x
            }
            return lhs.y < rhs.y
        }
    }
}
