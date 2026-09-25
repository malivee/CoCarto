struct PuzzleDefinition: Sendable {
    let id: PuzzleID
    let debugName: String
    let condition: PuzzleConditionDefinition
}

extension PuzzleDefinition {
    static let snowRoutePrototype = PuzzleDefinition(
        id: .snowRoutePrototype,
        debugName: "Connect Village to Outer Wilderness through Forest Pass",
        condition: .routeThroughPiece(
            from: .village,
            through: .forestPass,
            to: .outerWilderness
        )
    )
}
