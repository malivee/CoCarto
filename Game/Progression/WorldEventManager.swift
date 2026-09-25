final class WorldEventManager {
    var onDomainEvent: ((GameDomainEvent) -> Void)?

    private let definitions: [WorldEventDefinition]
    private let consequenceExecutor = WorldConsequenceExecutor()
    private(set) var progressState: WorldProgressState

    init(
        definitions: [WorldEventDefinition] = [.activateOuterExit],
        progressState: WorldProgressState = WorldProgressState()
    ) {
        self.definitions = definitions
        self.progressState = progressState
    }

    func reset() {
        progressState = WorldProgressState()
    }

    func restore(progressState: WorldProgressState) {
        self.progressState = progressState
    }

    @discardableResult
    func handle(_ event: GameDomainEvent, worldState: inout WorldState) -> [GameDomainEvent] {
        var emittedEvents: [GameDomainEvent] = []

        switch event {
        case .landmarkReached(.outerExit):
            if worldState.landmark(id: .outerExit)?.state == .active,
               progressState.prototypeStatus != .reachedExit {
                progressState.prototypeStatus = .reachedExit
                emittedEvents.append(event)
            }
        default:
            break
        }

        for definition in definitions where definition.trigger.matches(event) {
            guard progressState.events[definition.id]?.status != .completed else {
                continue
            }

            for consequence in definition.consequences {
                emittedEvents.append(contentsOf: consequenceExecutor.apply(consequence, to: &worldState))
            }

            progressState.events[definition.id] = WorldEventState(id: definition.id, status: .completed)
            if definition.id == .activateOuterExit, progressState.prototypeStatus == .exploring {
                progressState.prototypeStatus = .exitUnlocked
            }
            emittedEvents.append(.worldEventCompleted(definition.id))
        }

        for emittedEvent in emittedEvents {
            onDomainEvent?(emittedEvent)
        }
        return emittedEvents
    }

    func recordPuzzleStatus(_ status: PuzzleStatus, for id: PuzzleID) {
        progressState.puzzles[id] = PuzzleRuntimeState(id: id, status: status)
    }

    func status(for id: WorldEventID) -> WorldEventStatus {
        progressState.events[id]?.status ?? .inactive
    }
}
