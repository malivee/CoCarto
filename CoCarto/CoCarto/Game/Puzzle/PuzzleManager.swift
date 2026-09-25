final class PuzzleManager {
    var onPuzzleCompleted: ((PuzzleID) -> Void)?

    private let definitions: [PuzzleDefinition]
    private let evaluator = PuzzleEvaluator()
    private(set) var runtimeStates: [PuzzleID: PuzzleRuntimeState]

    init(definitions: [PuzzleDefinition] = [.snowRoutePrototype]) {
        self.definitions = definitions
        runtimeStates = Dictionary(uniqueKeysWithValues: definitions.map {
            ($0.id, PuzzleRuntimeState(id: $0.id, status: .active))
        })
    }

    func reset() {
        runtimeStates = Dictionary(uniqueKeysWithValues: definitions.map {
            ($0.id, PuzzleRuntimeState(id: $0.id, status: .active))
        })
    }

    func restore(runtimeStates: [PuzzleID: PuzzleRuntimeState]) {
        self.runtimeStates = runtimeStates
    }

    func evaluate(worldState: WorldState) {
        for definition in definitions {
            guard var runtimeState = runtimeStates[definition.id], runtimeState.status == .active else {
                continue
            }

            if evaluator.evaluate(definition: definition, worldState: worldState) {
                runtimeState.status = .completed
                runtimeStates[definition.id] = runtimeState
                onPuzzleCompleted?(definition.id)
            }
        }
    }

    func status(for id: PuzzleID) -> PuzzleStatus {
        runtimeStates[id]?.status ?? .inactive
    }

    func currentConditionIsSatisfied(for id: PuzzleID, worldState: WorldState) -> Bool {
        guard let definition = definitions.first(where: { $0.id == id }) else {
            return false
        }
        return evaluator.evaluate(definition: definition, worldState: worldState)
    }

    func debugEvaluation(for id: PuzzleID, worldState: WorldState) -> String {
        guard let definition = definitions.first(where: { $0.id == id }) else {
            return "Puzzle missing: \(id.rawValue)"
        }
        return evaluator.debugPuzzleEvaluation(definition: definition, worldState: worldState)
    }
}
