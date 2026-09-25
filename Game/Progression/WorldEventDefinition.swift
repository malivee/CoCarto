struct WorldEventDefinition: Equatable, Sendable {
    let id: WorldEventID
    let trigger: WorldEventTrigger
    let consequences: [WorldConsequence]
}

extension WorldEventDefinition {
    static let activateOuterExit = WorldEventDefinition(
        id: .activateOuterExit,
        trigger: .puzzleCompleted(.snowRoutePrototype),
        consequences: [.activateLandmark(.outerExit)]
    )
}
