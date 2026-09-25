struct WorldRoleCellResolver: Sendable {
    func cells(for role: PieceRole, in worldState: WorldState) -> Set<GridPosition> {
        Set(
            worldState.pieces
                .filter { $0.role == role }
                .flatMap { $0.resolvedCells().map(\.globalPosition) }
        )
    }
}
