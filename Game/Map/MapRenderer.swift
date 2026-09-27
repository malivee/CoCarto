import SpriteKit
import Foundation

final class MapRenderer {
    private(set) var mapper = MapGridMapper(cellSize: 96, origin: .zero)
    private(set) var cameraCenter = CGPoint.zero
    private(set) var inventoryExpanded = false
    private(set) var inventoryScrollOffset: CGFloat = 0
    private(set) var selectedInventoryIndex = 0
    private(set) var availableInventoryKinds = BuildingObjectKind.allCases
    private(set) var contentScale: CGFloat = 1
    private var lastRenderedSelectionID: UUID?
    private let mapCellSize: CGFloat
    private let worldCellSize: CGFloat
    private var currentTutorialTarget: BuildingObject?
    private var newInventoryKinds: Set<BuildingObjectKind> = []
    private var seenInventoryKinds: Set<BuildingObjectKind>
    private let seenInventoryKindsKey = "cocarto.ui.seen-building-kinds.v1"

    init(mapCellSize: CGFloat = 96, worldCellSize: CGFloat = 256) {
        self.mapCellSize = mapCellSize
        self.worldCellSize = worldCellSize
        if let storedKinds = UserDefaults.standard.stringArray(forKey: seenInventoryKindsKey) {
            self.seenInventoryKinds = Set(storedKinds.compactMap(BuildingObjectKind.init(rawValue:)))
        } else {
            self.seenInventoryKinds = [.arthurHouse, .well]
        }
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
        selectedObjectKind: BuildingObjectKind? = nil,
        objectPreview: BuildingObject? = nil,
        unlockedObjectKinds: Set<BuildingObjectKind> = Set(BuildingObjectKind.allCases),
        questItems: [MapQuestItem] = [],
        tutorialStep: MapTutorialStep? = nil
    ) {
        mapRoot.removeAllChildren()
        let tutorialKind = tutorialStep?.dragDemoKind ?? tutorialStep?.placementKind
        currentTutorialTarget = tutorialKind.flatMap {
            TutorialBuildingPlacementResolver.target(for: $0, in: worldState)
        }
        var unavailableKinds = Set(worldState.buildingObjects.map(\.kind))
        if worldState.buildingObjects.filter({ $0.kind == .rockSalt }).count < 3 {
            unavailableKinds.remove(.rockSalt)
        }
        if let selectedObjectKind {
            unavailableKinds.insert(selectedObjectKind)
        }
        availableInventoryKinds = BuildingObjectKind.allCases.filter {
            unlockedObjectKinds.contains($0) && !unavailableKinds.contains($0)
        }
        newInventoryKinds.formUnion(unlockedObjectKinds.subtracting(seenInventoryKinds))
        let visibleNewInventoryKinds = newInventoryKinds.intersection(availableInventoryKinds)
        scrollInventory(by: 0)
        if availableInventoryKinds.isEmpty {
            selectedInventoryIndex = 0
        } else {
            selectedInventoryIndex = min(selectedInventoryIndex, availableInventoryKinds.count - 1)
        }
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
        let shouldHighlightVillageSoil = selectedObjectKind != nil || objectPreview != nil
        for piece in worldState.pieces {
            var renderedPiece = piece
            if let preview, preview.pieceID == piece.id {
                renderedPiece.gridPosition = preview.proposedPosition
                renderedPiece.rotation = preview.proposedRotation
            }
            let state = interactionState(
                for: piece,
                in: worldState,
                preview: preview,
                playerConnectedPieceIDs: playerConnectedPieceIDs
            )
            let mismatchedEdges = preview?.pieceID == piece.id
                ? Array(PlacementValidator().mismatchedEdgeDirections(
                    pieceID: piece.id,
                    at: renderedPiece.gridPosition,
                    rotation: renderedPiece.rotation,
                    in: worldState
                ))
                : []
            let pieceNode = MapPieceNode(
                piece: renderedPiece,
                mapper: mapper,
                interactionState: state,
                mismatchedEdgesByLocalCell: mismatchedEdges
            )
            contentRoot.addChild(pieceNode)
            if shouldHighlightVillageSoil {
                addVillageSoilMicrogridOverlay(to: pieceNode, piece: renderedPiece)
            }
            if tutorialStep == .selectTile, piece.isMovable {
                addTutorialGlow(around: pieceNode, in: contentRoot)
            }
        }

        if let tutorialStep,
           let preview,
           let piece = worldState.piece(id: preview.pieceID),
           let targetPiece = tutorialPieceTarget(for: tutorialStep, piece: piece, preview: preview, worldState: worldState) {
            addTutorialPieceTarget(targetPiece, tutorialStep: tutorialStep, in: contentRoot)
        }

        let displayedWorldState: WorldState
        if let preview {
            displayedWorldState = worldState.previewingPiece(
                id: preview.pieceID,
                at: preview.proposedPosition,
                rotation: preview.proposedRotation
            )
        } else {
            displayedWorldState = worldState
        }
        BuildingObjectRenderer.render(
            displayedWorldState.buildingObjects,
            in: contentRoot,
            cellSize: mapCellSize,
            isWorld: false
        )

        if let objectPreview {
            let result = BuildingPlacementValidator().validate(objectPreview, in: worldState)
            let previewNode = BuildingObjectRenderer.makeNode(
                objectPreview,
                cellSize: mapCellSize,
                isWorld: false,
                result: result
            )
            contentRoot.addChild(previewNode)
            if tutorialStep?.isBuildingPlacementStep == true {
                addTutorialGlow(around: previewNode, in: contentRoot, color: result == .valid ? .systemGreen : .systemYellow)
            }
        }

        if let tutorialStep {
            if case .tryWrongSoil(let kind) = tutorialStep,
               let invalidTarget = tutorialInvalidBuildingTarget(for: kind, in: worldState) {
                addTutorialBuildingTarget(invalidTarget, result: .requiresVillageSoil, in: contentRoot)
            } else if let target = currentTutorialTarget,
                      objectPreview.map({ !matchesCurrentTutorialTarget($0) }) ?? true {
                addTutorialBuildingTarget(target, result: .valid, in: contentRoot)
            }
        }

        if tutorialStep == .enterWorld,
           let arthurHouse = worldState.buildingObjects.first(where: { $0.kind == .arthurHouse }),
           let housePiece = tutorialEntryPiece(for: arthurHouse, in: worldState),
           let tileNode = contentRoot.children.compactMap({ $0 as? MapPieceNode })
            .first(where: { $0.pieceID == housePiece.id }) {
            addTutorialGlow(around: tileNode, in: contentRoot)
        }

        if let footprintRectangle {
            contentRoot.addChild(makeFootprintOverlay(for: footprintRectangle))
        }

        if let spatialState = playerState.spatialState,
           let markerPosition = mapMarkerPosition(for: spatialState, worldState: worldState, preview: preview) {
            contentRoot.addChild(makePlayerMarker(at: markerPosition))
        }

        let hud = MapHUDNode(
            inventoryKinds: availableInventoryKinds,
            newInventoryKinds: visibleNewInventoryKinds
        )
        let shouldAnimateSelection = preview != nil && preview?.pieceID != lastRenderedSelectionID
        hud.layout(
            cameraCenter: CGPoint.zero,
            sceneSize: sceneSize,
            preview: preview,
            inventoryExpanded: inventoryExpanded,
            inventoryScrollOffset: inventoryScrollOffset,
            inventorySelectionTitle: availableInventoryKinds.isEmpty
                ? "Build"
                : BuildingObjectCatalog.definition(for: availableInventoryKinds[selectedInventoryIndex]).title,
            animateSelection: shouldAnimateSelection,
            selectedObjectKind: selectedObjectKind,
            objectPreview: objectPreview,
            objectResult: objectPreview.map { BuildingPlacementValidator().validate($0, in: worldState) },
            questItems: questItems,
            tutorialStep: tutorialStep
        )
        lastRenderedSelectionID = preview?.pieceID
        mapRoot.addChild(hud)

        if inventoryExpanded,
           let tutorialStep,
           let kind = tutorialStep.dragDemoKind {
            addTutorialDragDemo(
                kind: kind,
                sceneSize: sceneSize,
                contentOffset: contentOffset,
                to: mapRoot
            )
        }
    }

    func hasUnseenBuilding(_ kind: BuildingObjectKind) -> Bool {
        !seenInventoryKinds.contains(kind)
    }

    func announceNewBuilding(_ kind: BuildingObjectKind) {
        seenInventoryKinds.remove(kind)
        newInventoryKinds.insert(kind)
        inventoryExpanded = false
        inventoryScrollOffset = 0
        persistSeenInventoryKinds()
    }

    func toggleInventory() {
        inventoryExpanded.toggle()
    }

    func scrollInventory(by delta: CGFloat) {
        let contentHeight = CGFloat(availableInventoryKinds.count) * MapHUDNode.inventoryItemHeight + 20
        let viewportHeight = MapHUDNode.inventoryPanelHeight - 8
        let maximumOffset = max(0, contentHeight - viewportHeight)
        inventoryScrollOffset = min(max(inventoryScrollOffset + delta, 0), maximumOffset)
    }

    func selectInventoryItem(at index: Int) {
        guard availableInventoryKinds.indices.contains(index) else { return }
        selectedInventoryIndex = index
        markInventoryKindSeen(availableInventoryKinds[index])
        inventoryExpanded = false
        inventoryScrollOffset = 0
    }

    func resetSeenInventoryKinds() {
        seenInventoryKinds = [.arthurHouse, .well]
        newInventoryKinds.removeAll()
        persistSeenInventoryKinds()
    }

    private func markInventoryKindSeen(_ kind: BuildingObjectKind) {
        seenInventoryKinds.insert(kind)
        newInventoryKinds.remove(kind)
        persistSeenInventoryKinds()
    }

    private func persistSeenInventoryKinds() {
        UserDefaults.standard.set(seenInventoryKinds.map(\.rawValue).sorted(), forKey: seenInventoryKindsKey)
    }

    func inventoryKind(at index: Int) -> BuildingObjectKind? {
        guard availableInventoryKinds.indices.contains(index) else { return nil }
        return availableInventoryKinds[index]
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
        worldState: WorldState? = nil,
        animated: Bool = false,
        clockwise: Bool? = nil
    ) {
        guard let node = pieceNode(pieceID: piece.id, in: mapRoot) else {
            return
        }
        let mismatchedEdges = worldState.map {
            Array(PlacementValidator().mismatchedEdgeDirections(
                pieceID: preview.pieceID,
                at: preview.proposedPosition,
                rotation: preview.proposedRotation,
                in: $0
            ))
        } ?? []
        node.applyPreview(
            piece: piece,
            preview: preview,
            mapper: mapper,
            animated: animated,
            clockwise: clockwise,
            mismatchedEdgesByLocalCell: mismatchedEdges
        )
        if let worldState {
            updateBuildingPreview(preview, in: mapRoot, worldState: worldState)
        }
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

    /// Chooses a scale that fits the complete puzzle in the first map view.
    func setInitialPuzzleScale(for bounds: CGRect, sceneSize: CGSize) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let availableWidth = sceneSize.width * 0.86
        let availableHeight = sceneSize.height * 0.68
        contentScale = min(1, max(0.55, min(availableWidth / bounds.width, availableHeight / bounds.height)))
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
        in worldState: WorldState,
        preview: PiecePlacementPreview?,
        playerConnectedPieceIDs: Set<UUID>
    ) -> MapPieceInteractionState {
        if preview?.pieceID == piece.id {
            return .selected(isValid: preview?.isValid ?? true)
        }

        if playerConnectedPieceIDs.contains(piece.id) {
            return .playerConnected
        }

        if !piece.isMovable || !worldState.canMovePieceWithBuildings(pieceID: piece.id) {
            return .fixed
        }

        return .movable
    }

    private func updateBuildingPreview(
        _ preview: PiecePlacementPreview,
        in mapRoot: SKNode,
        worldState: WorldState
    ) {
        guard let contentRoot = contentRoot(in: mapRoot),
              let buildingRoot = contentRoot.childNode(withName: BuildingObjectRenderer.rootName) else {
            return
        }

        let displayedWorld = worldState.previewingPiece(
            id: preview.pieceID,
            at: preview.proposedPosition,
            rotation: preview.proposedRotation
        )
        let attachedObjectIDs = Set(
            worldState.buildingObjectsSupported(byPieceID: preview.pieceID).map(\.id)
        )
        for object in displayedWorld.buildingObjects where attachedObjectIDs.contains(object.id) {
            buildingRoot.children.first(where: {
                $0.userData?[BuildingObjectRenderer.objectIDKey] as? String == object.id.uuidString
            })?.removeFromParent()
            buildingRoot.addChild(
                BuildingObjectRenderer.makeNode(object, cellSize: mapCellSize, isWorld: false)
            )
        }
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

    private func addVillageSoilMicrogridOverlay(to pieceNode: SKNode, piece: WorldPiece) {
        let root = SKNode()
        root.name = "VillageSoilMicrogridOverlay"
        root.zPosition = 35
        let microSize = mapCellSize / CGFloat(MicroBiomeGrid.dimension)
        let halfCellSize = mapCellSize / 2

        for cell in piece.cellDefinitions {
            let microBiomeGrid = BuildingPuzzleCellID(rawValue: cell.id.rawValue)
                .map { BuildingPuzzleBiomeFixture.grid(for: $0) }
                ?? cell.microBiomeGrid
            let cellOrigin = mapper.offset(for: cell.localPosition)
            for position in MicroGridPosition.allPositions where microBiomeGrid.biome(at: position) == .villageSoil {
                let node = SKShapeNode(rectOf: CGSize(width: microSize - 1.5, height: microSize - 1.5), cornerRadius: 1.5)
                node.position = CGPoint(
                    x: cellOrigin.x - halfCellSize + CGFloat(position.x) * microSize + microSize / 2,
                    y: cellOrigin.y + halfCellSize - CGFloat(position.y) * microSize - microSize / 2
                )
                node.fillColor = SKColor.systemGreen.withAlphaComponent(0.10)
                node.strokeColor = SKColor.systemGreen.withAlphaComponent(0.92)
                node.lineWidth = 1.2
                node.glowWidth = 1.8
                root.addChild(node)
            }
        }

        guard !root.children.isEmpty else { return }
        root.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.42, duration: 0.55),
            .fadeAlpha(to: 0.86, duration: 0.55)
        ])))
        pieceNode.addChild(root)
    }

    private func makeFootprintOverlay(for rectangle: GlobalMicroRectangle) -> SKNode {
        let root = SKNode()
        root.zPosition = 240
        let microSize = mapCellSize / CGFloat(MicroBiomeGrid.dimension)
        for position in rectangle.positions() {
            let node = SKSpriteNode(
                color: SKColor.systemYellow.withAlphaComponent(0.72),
                size: CGSize(width: microSize - 1, height: microSize - 1)
            )
            node.position = microgridMapPosition(for: position, microSize: microSize)
            root.addChild(node)
        }
        return root
    }

    private func microgridMapPosition(for position: GridPosition, microSize: CGFloat) -> CGPoint {
        microgridMapPosition(x: position.x, y: position.y, microSize: microSize)
    }

    private func microgridMapPosition(for position: GlobalMicroPosition, microSize: CGFloat) -> CGPoint {
        microgridMapPosition(x: position.x, y: position.y, microSize: microSize)
    }

    private func microgridMapPosition(x: Int, y: Int, microSize: CGFloat) -> CGPoint {
        let largeCell = GridPosition(
            x: Int(floor(Double(x) / Double(MicroBiomeGrid.dimension))),
            y: Int(floor(Double(y) / Double(MicroBiomeGrid.dimension)))
        )
        let localX = x - largeCell.x * MicroBiomeGrid.dimension
        let localY = y - largeCell.y * MicroBiomeGrid.dimension
        let cellCenter = mapper.mapPosition(for: largeCell)
        let topLeft = CGPoint(
            x: cellCenter.x - mapCellSize / 2 + microSize / 2,
            y: cellCenter.y + mapCellSize / 2 - microSize / 2
        )
        return CGPoint(
            x: topLeft.x + CGFloat(localX) * microSize,
            y: topLeft.y - CGFloat(localY) * microSize
        )
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

    private func addTutorialPieceTarget(
        _ piece: WorldPiece,
        tutorialStep: MapTutorialStep,
        in parent: SKNode
    ) {
        let isWrongTarget: Bool
        if case .tryMismatchedTile = tutorialStep {
            isWrongTarget = true
        } else {
            isWrongTarget = false
        }
        let targetNode = MapPieceNode(
            piece: piece,
            mapper: mapper,
            interactionState: .selected(isValid: !isWrongTarget)
        )
        targetNode.name = "TutorialTileTarget"
        targetNode.alpha = 0.34
        targetNode.zPosition = 18
        parent.addChild(targetNode)
        addTutorialGlow(around: targetNode, in: parent, color: isWrongTarget ? .systemRed : .systemGreen)
    }

    private func addTutorialBuildingTarget(_ object: BuildingObject, result: BuildingPlacementResult, in parent: SKNode) {
        let node = BuildingObjectRenderer.makeNode(object, cellSize: mapCellSize, isWorld: false, result: result)
        node.name = "TutorialBuildingTarget"
        node.userData = nil
        node.alpha = result == .valid ? 0.42 : 0.36
        parent.addChild(node)
        addTutorialGlow(around: node, in: parent, color: result == .valid ? .systemGreen : .systemRed)
    }

    private func addTutorialGlow(
        around node: SKNode,
        in parent: SKNode,
        color: SKColor = SKColor(red: 1.0, green: 0.80, blue: 0.24, alpha: 1.0)
    ) {
        let frame = node.calculateAccumulatedFrame().insetBy(dx: -7, dy: -7)
        guard frame.width > 0, frame.height > 0 else { return }
        let glow = SKShapeNode(rect: frame, cornerRadius: 8)
        glow.name = "TutorialGlow"
        glow.fillColor = .clear
        glow.strokeColor = color
        glow.lineWidth = 3
        glow.glowWidth = 5
        glow.zPosition = 75
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.38, duration: 0.65),
            .fadeAlpha(to: 1.0, duration: 0.65)
        ])))
        parent.addChild(glow)
    }

    private func tutorialPieceTarget(
        for step: MapTutorialStep,
        piece: WorldPiece,
        preview: PiecePlacementPreview,
        worldState: WorldState
    ) -> WorldPiece? {
        let wantsMismatch: Bool
        switch step {
        case .tryMismatchedTile:
            wantsMismatch = true
        case .tryMatchingTile:
            wantsMismatch = false
        default:
            return nil
        }

        let validator = PlacementValidator()
        let origin = preview.originalPlacement.gridPosition
        let offsets = (-5...5).flatMap { y in
            (-5...5).map { x in GridPosition(x: x, y: y) }
        }
            .filter { $0.x != 0 || $0.y != 0 }
            .sorted {
                let left = abs($0.x) + abs($0.y)
                let right = abs($1.x) + abs($1.y)
                if left != right { return left < right }
                if abs($0.y) != abs($1.y) { return abs($0.y) < abs($1.y) }
                return abs($0.x) < abs($1.x)
            }

        for offset in offsets {
            let position = GridPosition(x: origin.x + offset.x, y: origin.y + offset.y)
            guard touchesAnotherPiece(piece: piece, at: position, rotation: preview.proposedRotation, in: worldState) else {
                continue
            }
            let mismatches = validator.mismatchedEdgeDirections(
                pieceID: piece.id,
                at: position,
                rotation: preview.proposedRotation,
                in: worldState
            )
            let isValid = validator.canPlace(
                pieceID: piece.id,
                at: position,
                rotation: preview.proposedRotation,
                in: worldState
            )
            guard wantsMismatch ? !mismatches.isEmpty : isValid else {
                continue
            }
            var target = piece
            target.gridPosition = position
            target.rotation = preview.proposedRotation
            return target
        }
        return nil
    }

    private func touchesAnotherPiece(
        piece: WorldPiece,
        at position: GridPosition,
        rotation: GridRotation,
        in worldState: WorldState
    ) -> Bool {
        let proposedCells = piece.occupiedCells(at: position, rotation: rotation)
        let otherCells = worldState.pieces
            .filter { $0.id != piece.id }
            .reduce(into: Set<GridPosition>()) { result, other in
                result.formUnion(other.occupiedCells())
            }
        return proposedCells.contains { cell in
            Direction.allCases.contains { direction in
                otherCells.contains(cell + direction.gridOffset)
            }
        }
    }

    private func tutorialInvalidBuildingTarget(for kind: BuildingObjectKind, in worldState: WorldState) -> BuildingObject? {
        let validator = BuildingPlacementValidator()
        let occupied = worldState.buildingObjects.reduce(into: Set<GridPosition>()) {
            $0.formUnion($1.occupiedPositions)
        }
        let tilePositions = validator.tilePositions(in: worldState)
        let candidates = tilePositions.sorted {
            if $0.y != $1.y { return $0.y < $1.y }
            return $0.x < $1.x
        }
        for origin in candidates {
            let object = BuildingObject(kind: kind, origin: origin, rotation: .degrees0)
            guard object.occupiedPositions.isDisjoint(with: occupied),
                  validator.overlapsWorldTiles(object, in: worldState),
                  validator.validate(object, in: worldState) == .requiresVillageSoil else {
                continue
            }
            return object
        }
        return nil
    }

    private func tutorialEntryPiece(
        for house: BuildingObject,
        in worldState: WorldState
    ) -> WorldPiece? {
        let validator = BuildingPlacementValidator()
        return worldState.pieces
            .map { piece in
                (piece, house.occupiedPositions.intersection(validator.villagePositions(for: piece)).count)
            }
            .filter { $0.1 > 0 }
            .max { $0.1 < $1.1 }?
            .0
    }

    private func matchesCurrentTutorialTarget(_ object: BuildingObject) -> Bool {
        guard let target = currentTutorialTarget else { return false }
        return object.kind == target.kind
            && object.origin == target.origin
            && object.rotation == target.rotation
    }

    private func addTutorialDragDemo(
        kind: BuildingObjectKind,
        sceneSize: CGSize,
        contentOffset: CGPoint,
        to mapRoot: SKNode
    ) {
        guard let inventoryIndex = availableInventoryKinds.firstIndex(of: kind),
              let target = currentTutorialTarget,
              target.kind == kind else {
            return
        }

        let cameraScale: CGFloat = 1.35
        let halfWidth = sceneSize.width * cameraScale / 2
        let halfHeight = sceneSize.height * cameraScale / 2
        let topY = halfHeight - 116
        let start = CGPoint(
            x: -halfWidth + 14 + 114,
            y: topY - 50 - MapHUDNode.inventoryItemHeight / 2 - CGFloat(inventoryIndex) * MapHUDNode.inventoryItemHeight + inventoryScrollOffset
        )

        let preview = BuildingObjectRenderer.makeNode(
            target,
            cellSize: mapCellSize,
            isWorld: false,
            result: .valid
        )
        let contentDestination = preview.position
        let destination = CGPoint(
            x: contentDestination.x * contentScale + contentOffset.x,
            y: contentDestination.y * contentScale + contentOffset.y
        )
        preview.name = "TutorialDragDemo"
        preview.position = start
        preview.setScale(0.52)
        preview.alpha = 0
        preview.zPosition = 850

        let dimensions = target.mapDimensions
        let microSize = mapCellSize / CGFloat(MicroBiomeGrid.dimension)
        let glow = SKShapeNode(
            rectOf: CGSize(
                width: CGFloat(dimensions.width) * microSize + 10,
                height: CGFloat(dimensions.height) * microSize + 10
            ),
            cornerRadius: 7
        )
        glow.name = "TutorialGlow"
        glow.fillColor = .clear
        glow.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.24, alpha: 1.0)
        glow.lineWidth = 3
        glow.glowWidth = 5
        glow.zPosition = 8
        preview.addChild(glow)

        // A neutral touch indicator makes the motion read as a drag without
        // relying on an emoji or changing the building artwork.
        let touchIndicator = SKShapeNode(circleOfRadius: 11)
        touchIndicator.fillColor = SKColor.white.withAlphaComponent(0.34)
        touchIndicator.strokeColor = .white
        touchIndicator.lineWidth = 2
        touchIndicator.glowWidth = 3
        touchIndicator.position = CGPoint(
            x: 0,
            y: -CGFloat(dimensions.height) * microSize / 2 - 15
        )
        touchIndicator.zPosition = 9
        preview.addChild(touchIndicator)

        let travel = SKAction.group([
            .move(to: destination, duration: 1.45),
            .scale(to: contentScale, duration: 1.45)
        ])
        travel.timingMode = .easeInEaseOut
        let reset = SKAction.group([
            .move(to: start, duration: 0),
            .scale(to: 0.52, duration: 0)
        ])
        preview.run(.repeatForever(.sequence([
            .fadeIn(withDuration: 0.18),
            .wait(forDuration: 0.25),
            travel,
            .wait(forDuration: 1.0),
            .fadeOut(withDuration: 0.22),
            reset,
            .wait(forDuration: 0.35)
        ])))
        mapRoot.addChild(preview)
    }

}

private extension MapTutorialStep {
    var isBuildingPlacementStep: Bool {
        switch self {
        case .tryWrongSoil, .placeHouse, .placeWell:
            return true
        default:
            return false
        }
    }

    var dragDemoKind: BuildingObjectKind? {
        switch self {
        case .dragHouse:
            return .arthurHouse
        case .dragWell:
            return .well
        default:
            return nil
        }
    }

    var placementKind: BuildingObjectKind? {
        switch self {
        case .tryWrongSoil(let kind):
            return kind
        case .placeHouse:
            return .arthurHouse
        case .placeWell:
            return .well
        default:
            return nil
        }
    }
}
