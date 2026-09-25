enum PrototypeProgressStatus: String, Codable, Hashable, Sendable {
    case exploring
    case exitUnlocked
    case reachedExit
}

struct WorldProgressState: Codable, Equatable, Sendable {
    var puzzles: [PuzzleID: PuzzleRuntimeState]
    var events: [WorldEventID: WorldEventState]
    var prototypeStatus: PrototypeProgressStatus

    init(
        puzzles: [PuzzleID: PuzzleRuntimeState] = [.snowRoutePrototype: PuzzleRuntimeState(id: .snowRoutePrototype, status: .active)],
        events: [WorldEventID: WorldEventState] = [.activateOuterExit: WorldEventState(id: .activateOuterExit, status: .inactive)],
        prototypeStatus: PrototypeProgressStatus = .exploring
    ) {
        self.puzzles = puzzles
        self.events = events
        self.prototypeStatus = prototypeStatus
    }
}
