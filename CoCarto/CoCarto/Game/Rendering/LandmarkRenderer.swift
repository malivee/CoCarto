import SpriteKit

final class LandmarkRenderer {
    private let resolver = WorldLandmarkResolver()
    private var landmarkNodes: [LandmarkID: LandmarkNode] = [:]

    func buildLandmarks(from worldState: WorldState, into worldRoot: SKNode, mapper: WorldGridMapper) {
        for node in landmarkNodes.values {
            node.removeFromParent()
        }
        landmarkNodes.removeAll()
        applyLandmarks(from: worldState, into: worldRoot, mapper: mapper)
    }

    func applyLandmarks(from worldState: WorldState, into worldRoot: SKNode, mapper: WorldGridMapper) {
        let currentIDs = Set(worldState.landmarks.map(\.id))
        for removedID in Set(landmarkNodes.keys).subtracting(currentIDs) {
            landmarkNodes[removedID]?.removeFromParent()
            landmarkNodes[removedID] = nil
        }

        for landmark in worldState.landmarks {
            guard let position = resolver.worldPosition(for: landmark, in: worldState, mapper: mapper) else {
                landmarkNodes[landmark.id]?.isHidden = true
                continue
            }

            if let node = landmarkNodes[landmark.id] {
                node.isHidden = false
                node.apply(landmark: landmark, position: position)
            } else {
                let node = LandmarkNode(landmark: landmark, position: position)
                landmarkNodes[landmark.id] = node
                worldRoot.addChild(node)
            }
        }
    }

    func node(for id: LandmarkID) -> LandmarkNode? {
        landmarkNodes[id]
    }
}
