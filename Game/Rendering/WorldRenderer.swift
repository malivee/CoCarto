import SpriteKit

final class WorldRenderer {
    private let mapper: WorldGridMapper
    private let boundaryGenerator = WorldBoundaryGenerator()
    private let landmarkRenderer = LandmarkRenderer()
    private var pieceNodes: [UUID: WorldPieceNode] = [:]
    private weak var boundaryRoot: SKNode?

    init(mapper: WorldGridMapper) {
        self.mapper = mapper
    }

    func buildWorld(
        from worldState: WorldState,
        into worldRoot: SKNode,
        debugRoot: SKNode,
        showsDebugLabels: Bool
    ) {
        worldRoot.removeAllChildren()
        pieceNodes.removeAll()

        for piece in worldState.pieces {
            let node = WorldPieceNode(
                piece: piece,
                mapper: mapper,
                showsDebugLabels: showsDebugLabels
            )
            pieceNodes[piece.id] = node
            worldRoot.addChild(node)
        }

        rebuildBoundaries(from: worldState, in: worldRoot)
        WorldDecorationRenderer.render(worldState, in: worldRoot, mapper: mapper)
        landmarkRenderer.buildLandmarks(from: worldState, into: worldRoot, mapper: mapper)
        BuildingObjectRenderer.render(worldState.buildingObjects, in: worldRoot, cellSize: mapper.cellSize, isWorld: true)
    }

    func applyWorldState(_ worldState: WorldState, in worldRoot: SKNode, showsDebugLabels: Bool) {
        let existingIDs = Set(pieceNodes.keys)
        let currentIDs = Set(worldState.pieces.map(\.id))

        for removedID in existingIDs.subtracting(currentIDs) {
            pieceNodes[removedID]?.removeFromParent()
            pieceNodes[removedID] = nil
        }

        for piece in worldState.pieces {
            if let node = pieceNodes[piece.id] {
                node.apply(piece: piece)
            } else {
                let node = WorldPieceNode(
                    piece: piece,
                    mapper: mapper,
                    showsDebugLabels: showsDebugLabels
                )
                pieceNodes[piece.id] = node
                worldRoot.addChild(node)
            }
        }

        rebuildBoundaries(from: worldState, in: worldRoot)
        WorldDecorationRenderer.render(worldState, in: worldRoot, mapper: mapper)
        landmarkRenderer.applyLandmarks(from: worldState, into: worldRoot, mapper: mapper)
        BuildingObjectRenderer.render(worldState.buildingObjects, in: worldRoot, cellSize: mapper.cellSize, isWorld: true)
    }

    func animateLandmarkActivation(_ landmarkID: LandmarkID) {
        landmarkRenderer.node(for: landmarkID)?.playActivationPulse()
    }

    func pieceNode(for pieceID: UUID) -> WorldPieceNode? {
        pieceNodes[pieceID]
    }

    private func rebuildBoundaries(from worldState: WorldState, in worldRoot: SKNode) {
        boundaryRoot?.removeFromParent()

        let boundaries = boundaryGenerator.boundaries(for: worldState)
        let boundaryRoot = SKNode()
        boundaryRoot.name = "WorldBoundaryRoot"
        boundaryRoot.zPosition = 10
        worldRoot.addChild(boundaryRoot)
        self.boundaryRoot = boundaryRoot

        for boundary in boundaries {
            boundaryRoot.addChild(makeBoundaryNode(for: boundary))
        }
    }

    func makeBoundaryNode(for boundary: WorldBoundary) -> SKNode {
        let node = SKNode()
        let endpoints = boundaryEndpoints(for: boundary)
        let body = SKPhysicsBody(edgeFrom: endpoints.start, to: endpoints.end)
        body.categoryBitMask = PhysicsCategory.worldBoundary
        body.collisionBitMask = PhysicsCategory.player
        body.contactTestBitMask = 0
        body.restitution = 0
        body.friction = 0
        node.physicsBody = body

        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: endpoints.start)
        path.addLine(to: endpoints.end)
        shape.path = path
        shape.strokeColor = boundary.strokeColor
        shape.lineWidth = 8
        shape.zPosition = 20
        node.addChild(shape)

        return node
    }

    private func boundaryEndpoints(for boundary: WorldBoundary) -> (start: CGPoint, end: CGPoint) {
        let center = mapper.worldPosition(for: boundary.cell)
        let half = mapper.halfCellSize

        switch boundary.direction {
        case .north:
            return (
                CGPoint(x: center.x - half, y: center.y + half),
                CGPoint(x: center.x + half, y: center.y + half)
            )
        case .east:
            return (
                CGPoint(x: center.x + half, y: center.y + half),
                CGPoint(x: center.x + half, y: center.y - half)
            )
        case .south:
            return (
                CGPoint(x: center.x + half, y: center.y - half),
                CGPoint(x: center.x - half, y: center.y - half)
            )
        case .west:
            return (
                CGPoint(x: center.x - half, y: center.y - half),
                CGPoint(x: center.x - half, y: center.y + half)
            )
        }
    }
}

private extension WorldBoundary {
    var strokeColor: SKColor {
        switch type {
        case .outerVoid:
            return SKColor.white.withAlphaComponent(0.75)
        case .blockedEdge:
            return SKColor.systemRed.withAlphaComponent(0.85)
        case .forest:
            return SKColor.systemGreen.withAlphaComponent(0.9)
        case .cliff:
            return SKColor.systemOrange.withAlphaComponent(0.9)
        }
    }
}
