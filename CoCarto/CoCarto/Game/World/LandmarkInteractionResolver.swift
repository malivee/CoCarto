import CoreGraphics

struct LandmarkInteractionResolver: Sendable {
    let interactionRadius: CGFloat
    private let landmarkResolver = WorldLandmarkResolver()

    init(interactionRadius: CGFloat = 96) {
        self.interactionRadius = interactionRadius
    }

    func activeLandmarkReached(
        by playerPosition: CGPoint,
        in worldState: WorldState,
        mapper: WorldGridMapper
    ) -> LandmarkID? {
        for landmark in worldState.landmarks where landmark.state == .active {
            guard let landmarkPosition = landmarkResolver.worldPosition(for: landmark, in: worldState, mapper: mapper) else {
                continue
            }

            if playerPosition.distance(to: landmarkPosition) <= interactionRadius {
                return landmark.id
            }
        }
        return nil
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}
