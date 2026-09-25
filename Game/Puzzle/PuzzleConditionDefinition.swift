enum PuzzleConditionDefinition: Equatable, Sendable {
    case routeThroughPiece(from: PieceRole, through: PieceRole, to: PieceRole)
}
