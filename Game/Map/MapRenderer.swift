import SpriteKit

final class MapRenderer {
    private(set) var mapper = MapGridMapper(cellSize: 96, origin: .zero)
    private(set) var cameraCenter = CGPoint.zero
    private(set) var inventoryExpanded = false
    private(set) var inventoryScrollOffset: CGFloat = 0
    private(set) var selectedInventoryIndex = 0
    private(set) var contentScale: CGFloat = 1
    private var lastRenderedSelectionID: UUID?
    private let inventoryTitles = ["House", "Workshop", "Farm", "Market", "Bridge", "Tower"]
    private let mapCellSize: CGFloat
    private let worldCellSize: CGFloat

    init(mapCellSize: CGFloat = 96, worldCellSize: CGFloat = 256) {
        self.mapCellSize = mapCellSize
        self.worldCellSize = worldCellSize
    }

    func buildMap(
        from worldState: WorldState,
        in mapRoot: SKNode,
        sceneSize: CGSize,
        playerState: PlayerState,
        preview: PiecePlacementPreview?,
        contentOffset: CGPoint,
        puzzleStatusText: String = "Goal: shape Village Soil",
        footprintRectangle: GlobalMicroRectangle? = nil,
        questItems: [MapQuestItem] = []
    ) {
        mapRoot.removeAllChildren()
        mapper = makeMapper(sceneSize: sceneSize)
        cameraCenter = .zero

        let background = makeBackground(sceneSize: sceneSize)
        mapRoot.addChild(background)

        let contentRoot = SKNode()
        contentRoot.name = MapNodeName.contentRoot.rawValue
        contentRoot.position = contentOffset
        contentRoot.setScale(contentScale)
        mapRoot.addChild(contentRoot)

        let playerConnectedPieceIDs = playerConnectedPieceIDs(
            in: worldState,
            playerState: playerState,
            preview: preview
        )
        for piece in worldState.pieces {
            var renderedPiece = piece
            if let preview, preview.pieceID == piece.id {
                renderedPiece.gridPosition = preview.proposedPosition
                renderedPiece.rotation = preview.proposedRotation
            }
            let state = interactionState(
                for: piece,
                preview: preview,
                playerConnectedPieceIDs: playerConnectedPieceIDs
            )
            contentRoot.addChild(MapPieceNode(piece: renderedPiece, mapper: mapper, interactionState: state))
        }

        if let footprintRectangle {
            contentRoot.addChild(makeFootprintOverlay(for: footprintRectangle))
        }

        if let spatialState = playerState.spatialState,
           let markerPosition = mapMarkerPosition(for: spatialState, worldState: worldState, preview: preview) {
            contentRoot.addChild(makePlayerMarker(at: markerPosition))
        }

        let hud = MapHUDNode()
        let shouldAnimateSelection = preview != nil && preview?.pieceID != lastRenderedSelectionID
        hud.layout(
            cameraCenter: .zero,
            sceneSize: sceneSize,
            preview: preview,
            inventoryExpanded: inventoryExpanded,
            inventoryScrollOffset: inventoryScrollOffset,
            inventorySelectionTitle: inventoryTitles[selectedInventoryIndex],
            questItems: questItems,
            animateSelection: shouldAnimateSelection
        )
        lastRenderedSelectionID = preview?.pieceID
        mapRoot.addChild(hud)
    }

    func toggleInventory() {
        inventoryExpanded.toggle()
    }

    func scrollInventory(by delta: CGFloat) {
        let contentHeight: CGFloat = 6 * 58
        let viewportHeight: CGFloat = 356
        let maximumOffset = max(0, contentHeight - viewportHeight + 12)
        inventoryScrollOffset = min(max(inventoryScrollOffset + delta, 0), maximumOffset)
    }

    func selectInventoryItem(at index: Int) {
        guard inventoryTitles.indices.contains(index) else { return }
        selectedInventoryIndex = index
        inventoryExpanded = false
        inventoryScrollOffset = 0
    }

    func applyContentOffset(_ contentOffset: CGPoint, in mapRoot: SKNode) {
        contentRoot(in: mapRoot)?.position = contentOffset
    }

    @discardableResult
    func setContentScale(_ scale: CGFloat, in mapRoot: SKNode) -> CGFloat {
        contentScale = min(max(scale, 0.55), 1.8)
        contentRoot(in: mapRoot)?.setScale(contentScale)
        return contentScale
    }

    func screenPointToContent(_ screenPoint: CGPoint, contentOffset: CGPoint) -> CGPoint {
        CGPoint(
            x: (screenPoint.x - contentOffset.x) / contentScale,
            y: (screenPoint.y - contentOffset.y) / contentScale
        )
    }

    func contentRoot(in mapRoot: SKNode) -> SKNode? {
        mapRoot.childNode(withName: MapNodeName.contentRoot.rawValue)
    }

    func updatePreviewNode(
        piece: WorldPiece,
        preview: PiecePlacementPreview,
        in mapRoot: SKNode,
        animated: Bool = false,
        clockwise: Bool? = nil
    ) {
        guard let node = pieceNode(pieceID: piece.id, in: mapRoot) else {
            return
        }
        node.applyPreview(
            piece: piece,
            preview: preview,
            mapper: mapper,
            animated: animated,
            clockwise: clockwise
        )
    }

    func animatePreviewSnap(pieceID: UUID, to position: CGPoint, in mapRoot: SKNode, completion: @escaping () -> Void) {
        guard let node = pieceNode(pieceID: pieceID, in: mapRoot) else {
            completion()
            return
        }

        node.removeAction(forKey: "snap")
        let action = SKAction.move(to: position, duration: 0.12)
        action.timingMode = .easeOut
        node.run(action, completion: completion)
    }

    func pieceNode(pieceID: UUID, in mapRoot: SKNode) -> MapPieceNode? {
        contentRoot(in: mapRoot)?.children.compactMap { $0 as? MapPieceNode }.first { $0.pieceID == pieceID }
    }

    func contentBounds(for worldState: WorldState) -> CGRect {
        let positions = worldState.pieces.flatMap { piece in
            piece.occupiedCells().map { mapper.mapPosition(for: $0) }
        }
        guard let first = positions.first else {
            return .zero
        }

        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y
        for position in positions.dropFirst() {
            minX = min(minX, position.x)
            maxX = max(maxX, position.x)
            minY = min(minY, position.y)
            maxY = max(maxY, position.y)
        }

        let half = mapCellSize / 2
        return CGRect(x: minX - half, y: minY - half, width: maxX - minX + mapCellSize, height: maxY - minY + mapCellSize)
    }

    func focusPoint(for playerState: PlayerState, worldState: WorldState, preview: PiecePlacementPreview?) -> CGPoint {
        if let spatialState = playerState.spatialState,
           let markerPosition = mapMarkerPosition(for: spatialState, worldState: worldState, preview: preview) {
            return markerPosition
        }

        guard let bounds = GridBounds(worldState: worldState) else {
            return .zero
        }
        return mapper.mapPosition(for: GridPosition(
            x: Int(bounds.centerGridPosition.x.rounded()),
            y: Int(bounds.centerGridPosition.y.rounded())
        ))
    }

    func mapMarkerPosition(
        for spatialState: PlayerSpatialState,
        worldState: WorldState,
        preview: PiecePlacementPreview?
    ) -> CGPoint? {
        guard var piece = worldState.piece(id: spatialState.pieceID) else {
            return nil
        }

        if let preview, preview.pieceID == piece.id {
            piece.gridPosition = preview.proposedPosition
            piece.rotation = preview.proposedRotation
        }

        let pieceOrigin = mapper.mapPosition(for: piece.gridPosition)
        let scaledLocal = CGPoint(
            x: spatialState.localPositionInPiece.x / worldCellSize * mapCellSize,
            y: spatialState.localPositionInPiece.y / worldCellSize * mapCellSize
        )
        let rotatedLocal = piece.rotation.rotated(scaledLocal)
        return CGPoint(x: pieceOrigin.x + rotatedLocal.x, y: pieceOrigin.y + rotatedLocal.y)
    }

    private func interactionState(
        for piece: WorldPiece,
        preview: PiecePlacementPreview?,
        playerConnectedPieceIDs: Set<UUID>
    ) -> MapPieceInteractionState {
        if preview?.pieceID == piece.id {
            return .selected(isValid: preview?.isValid ?? true)
        }

        if playerConnectedPieceIDs.contains(piece.id) {
            return .playerConnected
        }

        if !piece.isMovable {
            return .fixed
        }

        return .movable
    }

    private func playerConnectedPieceIDs(
        in worldState: WorldState,
        playerState: PlayerState,
        preview: PiecePlacementPreview?
    ) -> Set<UUID> {
        let displayedState: WorldState
        if let preview, preview.isValid {
            displayedState = worldState.previewingPiece(
                id: preview.pieceID,
                at: preview.proposedPosition,
                rotation: preview.proposedRotation
            )
        } else {
            displayedState = worldState
        }

        let reachableCells = ConnectedComponentResolver().reachableCells(
            from: playerState,
            in: displayedState
        )
        return Set(reachableCells.compactMap { displayedState.occupancy.pieceID(at: $0) })
    }

    private func makeMapper(sceneSize: CGSize) -> MapGridMapper {
        MapGridMapper(cellSize: mapCellSize, origin: .zero)
    }

    private func makeBackground(sceneSize: CGSize) -> SKNode {
        let node = SKShapeNode(rectOf: CGSize(width: sceneSize.width * 2.2, height: sceneSize.height * 2.2))
        node.position = .zero
        node.fillColor = SKColor(red: 0.035, green: 0.10, blue: 0.19, alpha: 1)
        node.strokeColor = .clear
        node.lineWidth = 0
        node.zPosition = -20
        node.name = MapNodeName.background.rawValue
        return node
    }

    private func makeFootprintOverlay(for rectangle: GlobalMicroRectangle) -> SKNode {
        let root = SKNode()
        root.zPosition = 240
        let microSize = mapCellSize / CGFloat(MicroBiomeGrid.dimension)
        for position in rectangle.positions() {
            let largeCell = GridPosition(
                x: Int(floor(Double(position.x) / Double(MicroBiomeGrid.dimension))),
                y: Int(floor(Double(position.y) / Double(MicroBiomeGrid.dimension)))
            )
            let localX = position.x - largeCell.x * MicroBiomeGrid.dimension
            let localY = position.y - largeCell.y * MicroBiomeGrid.dimension
            let cellCenter = mapper.mapPosition(for: largeCell)
            let topLeft = CGPoint(x: cellCenter.x - mapCellSize / 2 + microSize / 2, y: cellCenter.y + mapCellSize / 2 - microSize / 2)
            let node = SKSpriteNode(
                color: SKColor.systemYellow.withAlphaComponent(0.72),
                size: CGSize(width: microSize - 1, height: microSize - 1)
            )
            node.position = CGPoint(
                x: topLeft.x + CGFloat(localX) * microSize,
                y: topLeft.y - CGFloat(localY) * microSize
            )
            root.addChild(node)
        }
        return root
    }

    private func makePlayerMarker(at position: CGPoint) -> SKNode {
        let marker = SKShapeNode(circleOfRadius: mapCellSize * 0.16)
        marker.position = position
        marker.fillColor = .white
        marker.strokeColor = .cyan
        marker.lineWidth = 4
        marker.zPosition = 500
        return marker
    }
}
