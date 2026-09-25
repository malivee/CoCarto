import CoreGraphics

struct WorldLandmarkResolver: Sendable {
    func worldPosition(
        for landmark: WorldLandmark,
        in worldState: WorldState,
        mapper: WorldGridMapper
    ) -> CGPoint? {
        guard let piece = worldState.piece(role: landmark.pieceRole) else {
            return nil
        }

        let localPosition = CGPoint(
            x: CGFloat(landmark.localCell.x) * mapper.cellSize,
            y: CGFloat(landmark.localCell.y) * mapper.cellSize
        )
        return PieceWorldTransform(piece: piece, mapper: mapper).localToWorld(localPosition)
    }
}
