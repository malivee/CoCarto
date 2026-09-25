struct WorldConsequenceExecutor: Sendable {
    func apply(_ consequence: WorldConsequence, to worldState: inout WorldState) -> [GameDomainEvent] {
        switch consequence {
        case .activateLandmark(let landmarkID):
            guard worldState.landmark(id: landmarkID)?.state != .active else {
                return []
            }

            let didChange = worldState.setLandmarkState(.active, for: landmarkID)
            return didChange ? [.landmarkActivated(landmarkID)] : []
        }
    }
}
