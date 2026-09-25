import SpriteKit
import UIKit
import CoreImage

extension GameScene {
    func enterMapView() {
        guard gameMode == .exploring else {
            return
        }

        gameMode = .enteringMap
        inputController.endTouch()
        hideJoystick()
        if let playerNode {
            playerController.stop(playerNode: playerNode)
            playerController.updateState(from: playerNode.position)
        }

        mapController.cancel()
        playTransitionFog { [weak self] in
            guard let self, self.gameMode == .enteringMap else {
                return
            }

            let startingPosition = self.cameraNode.position
            let startingScale = self.cameraController.currentScale
            self.prepareMapForTransition()
            self.cameraController.beginTransitionToMap()
            let didStart = self.transitionController.beginWorldToMap(
                from: startingPosition,
                cameraScale: startingScale,
                to: self.mapRenderer.cameraCenter
            )
            if !didStart {
                self.transitionController.presentMapImmediately(at: self.mapRenderer.cameraCenter)
                self.finishWorldToMapTransition()
            }
        }
    }

    func exitMapView() {
        guard mapController.preview == nil else {
            return
        }

        startMapToWorldTransition()
    }

    func enterWorldByDoubleTappingTile(at _: CGPoint, pieceID: UUID) {
        guard worldState.piece(id: pieceID) != nil,
              let playerNode else {
            return
        }

        // A first tap may have selected this piece. A double tap is navigation,
        // so discard that transient edit before resolving the destination tile.
        mapController.cancel()
        rotationInputLocked = false

        playerNode.physicsBody?.velocity = .zero
        playerController.updateState(from: playerNode.position)
        startMapToWorldTransition()
    }

    func currentMapTutorialStep() -> MapTutorialStep? {
        // STRICT QUEST 1 CHECK: Tutorial ONLY appears during Quest 1 before water is collected
        guard isQuest1TutorialActive else { return nil }

        // STEP 1: Click & Rotate Tile Tutorial
        if !hasRotatedPieceInTutorial {
            if let preview = mapController.preview {
                return .rotateTile(isValid: preview.isValid)
            }
            return .selectTile
        }

        if let preview = mapController.preview {
            return .rotateTile(isValid: preview.isValid)
        }

        let hasArthurHome = worldState.buildingObjects.contains { $0.kind == .arthurHouse }
        let hasWell = worldState.buildingObjects.contains { $0.kind == .well }

        if let objectPreview {
            let isValid = BuildingPlacementValidator().validate(objectPreview, in: worldState) == .valid
            if objectPreview.kind == .well {
                return .placeWell(isValid: isValid)
            } else {
                return .placeHouse(isValid: isValid)
            }
        }
        if let selectedKind = selectedObjectKind {
            if selectedKind == .well {
                return .placeWell(isValid: false)
            } else {
                return .placeHouse(isValid: false)
            }
        }

        if !hasArthurHome {
            if mapRenderer.inventoryExpanded {
                return .dragHouse
            }
            return .openSidebar
        }

        if !hasWell {
            if mapRenderer.inventoryExpanded {
                return .dragWell
            }
            return .openSidebar
        }

        return .enterWorld
    }

    func rebuildMapView() {
        mapViewport.recalculateBounds(contentBounds: mapRenderer.contentBounds(for: worldState), sceneSize: size)
        mapRenderer.buildMap(
            from: worldState,
            in: mapRoot,
            sceneSize: size,
            playerState: playerController.state,
            preview: mapController.preview,
            contentOffset: mapViewport.contentOffset,
            puzzleStatusText: puzzleStatusText(),
            footprintRectangle: currentFootprintRectangle(),
            selectedObjectKind: selectedObjectKind,
            objectPreview: objectPreview,
            unlockedObjectKinds: questUnlockedObjectKinds(),
            questItems: mapQuestItems(),
            tutorialStep: currentMapTutorialStep()
        )
    }

    func prepareMapForTransition() {
        worldQuestLabel.isHidden = true
        worldQuestTracker.isHidden = true
        let focusPoint = mapRenderer.focusPoint(for: playerController.state, worldState: worldState, preview: nil)
        mapViewport.reset(contentBounds: mapRenderer.contentBounds(for: worldState), sceneSize: size, focusPoint: focusPoint)
        rebuildMapView()
        worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)
        worldRoot.isHidden = false
        playerNode?.isHidden = false
        worldDebugRoot.isHidden = false
        mapRoot.isHidden = false
        mapDebugRoot.isHidden = false
        mapRoot.alpha = 0
        mapDebugRoot.alpha = 0
        enterMapButton.alpha = 1
        playerNode?.alpha = 1
    }

    func startMapToWorldTransition() {
        guard gameMode == .mapIdle || gameMode.isMapInteractionActive || gameMode == .committingMapChange else {
            return
        }

        gameMode = .exitingMap
        if isDraggingPlacedObject {
            restoreOriginalDraggedBuilding()
        }
        selectedObjectKind = nil
        objectPreview = nil
        mapController.cancel()
        playerController.updateWorldState(worldState)
        worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)
        worldRoot.isHidden = false
        playerNode?.isHidden = false
        worldDebugRoot.isHidden = false
        mapRoot.isHidden = false
        mapDebugRoot.isHidden = false
        let targetPosition = playerNode?.position ?? cameraNode.position
        playTransitionFog { [weak self] in
            guard let self, self.gameMode == .exitingMap else {
                return
            }

            // Recenter only while the screen is fully covered. The visible part
            // of the transition is then a pure zoom into the player's position,
            // without a sideways camera sweep.
            let startingScale = self.cameraController.currentScale
            self.cameraController.beginTransitionToWorld()
            self.cameraController.applyTransitionFrame(
                position: targetPosition,
                scale: startingScale
            )
            let didStart = self.transitionController.beginMapToWorld(
                from: targetPosition,
                cameraScale: startingScale,
                to: targetPosition
            )
            if !didStart {
                self.finishMapToWorldTransition()
            }
        }
    }

    func presentInitialMapOverview() {
        mapController.cancel()
        prepareMapForTransition()
        transitionController.presentMapImmediately(at: mapRenderer.cameraCenter)
        cameraController.snapToMapOverview(center: mapRenderer.cameraCenter)
        finishWorldToMapTransition()
    }

    func updateViewTransition(deltaTime: TimeInterval) {
        guard let frame = transitionController.update(deltaTime: deltaTime) else {
            if transitionController.state == .idleMap, gameMode == .enteringMap {
                finishWorldToMapTransition()
            } else if transitionController.state == .idleWorld, gameMode == .exitingMap {
                finishMapToWorldTransition()
            }
            return
        }

        applyTransitionFrame(frame)

        if transitionController.state == .idleMap, gameMode == .enteringMap {
            finishWorldToMapTransition()
        } else if transitionController.state == .idleWorld, gameMode == .exitingMap {
            finishMapToWorldTransition()
        }
    }

    func applyTransitionFrame(_ frame: MapWorldTransitionFrame) {
        cameraController.applyTransitionFrame(position: frame.cameraPosition, scale: frame.cameraScale)
        worldRoot.alpha = frame.worldAlpha
        worldDebugRoot.alpha = min(frame.worldAlpha, showsDebugOverlay ? 1 : 0)
        mapRoot.alpha = frame.mapAlpha
        mapDebugRoot.alpha = frame.mapAlpha
        playerNode?.alpha = frame.playerAlpha
        enterMapButton.alpha = frame.enterMapButtonAlpha
    }

    func finishWorldToMapTransition() {
        cameraController.setMapOverview(center: mapRenderer.cameraCenter)
        worldRoot.alpha = 0.08
        worldDebugRoot.alpha = 0
        mapRoot.alpha = 1
        mapDebugRoot.alpha = 1
        playerNode?.alpha = 0
        enterMapButton.alpha = 0
        resetButton.alpha = 0
        saveButton.alpha = 0
        loadButton.alpha = 0
        gameMode = .mapIdle
    }

    func finishMapToWorldTransition() {
        cameraController.returnToPlayerFollow()
        worldRoot.alpha = 1
        worldDebugRoot.alpha = showsDebugOverlay ? 1 : 0
        mapRoot.alpha = 0
        mapDebugRoot.alpha = 0
        playerNode?.alpha = 1
        enterMapButton.alpha = 1
        mapRoot.isHidden = true
        mapDebugRoot.isHidden = true
        gameMode = .exploring
        syncVillageNPCs()
        updateWorldQuestLabel()
        flushPendingPresentationEvents()
    }

    func handleMapTouchBegan(at location: CGPoint) {
        let stack = nodeStack(at: location)

        if let target = footprintDebugTarget(in: stack) {
            footprintDebugTarget = target
            rebuildMapView()
            return
        }

        if stack.contains(where: { $0.name == MapNodeName.rotateLeftButton.rawValue }) {
            rotateSelectedPiece(clockwise: false)
            return
        }

        if stack.contains(where: { $0.name == MapNodeName.rotateRightButton.rawValue }) {
            rotateSelectedPiece(clockwise: true)
            return
        }

        if stack.contains(where: { $0.name == MapNodeName.cancelButton.rawValue }) {
            if selectedObjectKind != nil {
                selectedObjectKind = nil
                objectPreview = nil
                if isDraggingPlacedObject {
                    restoreOriginalDraggedBuilding()
                }
                rebuildMapView()
                return
            }
            cancelMapPreview()
            return
        }

        if stack.contains(where: { $0.name == MapNodeName.confirmButton.rawValue }) {
            if selectedObjectKind != nil {
                if let objectPreview,
                   worldState.placeBuildingObject(objectPreview) == .valid {
                    let title = BuildingObjectCatalog.definition(for: objectPreview.kind).title
                    self.objectPreview = nil
                    selectedObjectKind = nil
                    isDraggingPlacedObject = false
                    originalDraggedBuilding = nil
                    syncQuest2PlacementProgress()
                    worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)
                    autosave(reason: "building placed")
                    AudioService.shared.playSFX("PaperMap")
                    showProgressionFeedback("\(title.uppercased()) PLACED")
                }
                rebuildMapView()
                return
            }
            confirmMapPreview()
            return
        }

        if stack.contains(where: { $0.name == MapNodeName.exitButton.rawValue }) {
            exitMapView()
            return
        }

        if let kind = selectedObjectKind {
            isDraggingObjectFromInventory = true
            updateObjectPreview(at: location, kind: kind)
            return
        }

        guard let pieceID = pieceID(in: stack) else {
            if mapController.preview != nil {
                finishCurrentSelection()
                return
            }
            mapController.beginPan(at: location)
            return
        }

        guard mapController.canManipulate(pieceID: pieceID, in: worldState, playerState: playerController.state) else {
            mapController.beginPan(at: location)
            return
        }

        _ = mapController.beginDrag(
            pieceID: pieceID,
            touchPositionInContent: mapRenderer.screenPointToContent(
                location,
                contentOffset: mapViewport.contentOffset
            ),
            mapper: mapRenderer.mapper,
            worldState: worldState,
            playerState: playerController.state
        )
        AudioService.shared.playSFX("PaperMap")
        lastMapDragScreenPosition = location
        gameMode = .mapDragging(pieceID)
        if let preview = mapController.preview,
           let piece = worldState.piece(id: preview.pieceID) {
            mapRenderer.updatePreviewNode(piece: piece, preview: preview, in: mapRoot, worldState: worldState)
        }
    }

    func rotateObject(clockwise: Bool) {
        objectRotation = clockwise ? objectRotation.nextQuarterTurn : objectRotation.previousQuarterTurn
        if let previous = objectPreview {
            objectPreview = BuildingObject(
                id: previous.id,
                kind: previous.kind,
                origin: previous.origin,
                rotation: objectRotation
            )
        }
        rebuildMapView()
    }

    func updateObjectPreview(at screenPosition: CGPoint, kind: BuildingObjectKind? = nil) {
        guard let kind = kind ?? selectedObjectKind else { return }
        objectRotation = .degrees0
        // Lift the actual building preview above the finger during a drag so the
        // player can see both the asset and its placement border clearly.
        let previewScreenPosition = isDraggingObjectFromInventory
            ? CGPoint(x: screenPosition.x, y: screenPosition.y + 54)
            : screenPosition
        let content = mapRenderer.screenPointToContent(
            previewScreenPosition,
            contentOffset: mapViewport.contentOffset
        )
        let microSize = mapRenderer.mapper.cellSize / CGFloat(MicroBiomeGrid.dimension)
        let template = BuildingObject(kind: kind, origin: .zero, rotation: .degrees0)
        let dimensions = template.mapDimensions
        let origin = GridPosition(
            x: Int(floor((content.x + mapRenderer.mapper.cellSize / 2) / microSize)) - dimensions.width / 2,
            y: Int(floor((content.y + mapRenderer.mapper.cellSize / 2) / microSize)) - dimensions.height / 2
        )
        let nextPreview = BuildingObject(
            id: objectPreview?.id ?? UUID(),
            kind: kind,
            origin: origin,
            rotation: .degrees0
        )
        if let objectPreview,
           objectPreview.kind == nextPreview.kind,
           objectPreview.origin == nextPreview.origin,
           objectPreview.rotation == nextPreview.rotation {
            return
        }
        objectPreview = nextPreview
        rebuildMapView()
    }

    func beginPlacedObjectDrag(id: UUID, at location: CGPoint) {
        guard let object = worldState.removeBuildingObject(id: id) else { return }
        mapController.cancel()
        originalDraggedBuilding = object
        selectedObjectKind = object.kind
        objectRotation = object.rotation
        objectPreview = object
        isDraggingPlacedObject = true
        isDraggingObjectFromInventory = true
        updateObjectPreview(at: location, kind: object.kind)
    }

    func finishObjectDrop() {
        guard let preview = objectPreview else {
            selectedObjectKind = nil
            isDraggingPlacedObject = false
            rebuildMapView()
            return
        }

        if BuildingPlacementValidator().validate(preview, in: worldState) == .valid {
            _ = worldState.placeBuildingObject(preview)
            syncQuest2PlacementProgress()
            let title = BuildingObjectCatalog.definition(for: preview.kind).title
            selectedObjectKind = nil
            objectPreview = nil
            isDraggingPlacedObject = false
            originalDraggedBuilding = nil
            worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)
            autosave(reason: "building dropped")
            AudioService.shared.playSFX("PaperMap")
            showProgressionFeedback("\(title.uppercased()) PLACED")
            rebuildMapView()
        } else {
            // Keep the preview active so it can be adjusted. A previously placed
            // building remains restorable if the player exits or cancels.
            AudioService.shared.playSFX("PaperMap")
            rebuildMapView()
        }
    }

    func restoreOriginalDraggedBuilding() {
        if let originalDraggedBuilding {
            _ = worldState.placeBuildingObject(originalDraggedBuilding)
        }
        originalDraggedBuilding = nil
        isDraggingPlacedObject = false
        autosave(reason: "building restored after invalid move")
    }

    func rotateSelectedPiece(clockwise: Bool) {
        guard !rotationInputLocked else { return }
        rotationInputLocked = true
        AudioService.shared.playSFX("PaperMap")
        guard let preview = mapController.rotateSelected(
            clockwise: clockwise,
            in: worldState,
            mapper: mapRenderer.mapper,
            locksInteraction: true
        ),
              let piece = worldState.piece(id: preview.pieceID) else {
            rotationInputLocked = false
            return
        }
        hasRotatedPieceInTutorial = true

        gameMode = .mapPieceSelected(preview.pieceID)
        mapRenderer.updatePreviewNode(
            piece: piece,
            preview: preview,
            in: mapRoot,
            worldState: worldState,
            animated: true,
            clockwise: clockwise
        )
        mapRoot.removeAction(forKey: "finishMapRotation")
        mapRoot.run(.sequence([
            .wait(forDuration: 0.12),
            .run { [weak self] in
                guard let self else { return }
                self.mapController.finishRotation()
                self.rotationInputLocked = false
                self.rebuildMapView()
            }
        ]), withKey: "finishMapRotation")
    }

    func updatePieceDrag(at screenPosition: CGPoint, pieceID: UUID) {
        lastMapDragScreenPosition = screenPosition
        let contentPosition = mapRenderer.screenPointToContent(
            screenPosition,
            contentOffset: mapViewport.contentOffset
        )
        guard let preview = mapController.updateDrag(
            touchPositionInContent: contentPosition,
            mapper: mapRenderer.mapper,
            worldState: worldState
        ), let piece = worldState.piece(id: preview.pieceID) else {
            return
        }

        mapRenderer.updatePreviewNode(piece: piece, preview: preview, in: mapRoot, worldState: worldState)
    }

    func finishPieceDrag(pieceID: UUID) {
        lastMapDragScreenPosition = nil
        guard let preview = mapController.resolveDrop(in: worldState, mapper: mapRenderer.mapper) else {
            gameMode = .mapIdle
            return
        }

        if mapController.shouldReturnSelectedPieceToBag(in: worldState) {
            let originalPosition = mapRenderer.mapper.mapPosition(for: preview.originalPlacement.gridPosition)
            mapRenderer.animatePreviewSnap(pieceID: pieceID, to: originalPosition, in: mapRoot) { [weak self] in
                guard let self else { return }
                self.mapController.cancel()
                self.gameMode = .mapIdle
                self.rebuildMapView()
                self.showProgressionFeedback("PIECE RETURNED TO BAG")
            }
            return
        }

        AudioService.shared.playSFX("PaperMap")
        gameMode = .mapPieceSelected(pieceID)
        mapRenderer.animatePreviewSnap(pieceID: pieceID, to: preview.visualPosition, in: mapRoot) { [weak self] in
            guard let self,
                  let currentPreview = self.mapController.preview,
                  let piece = self.worldState.piece(id: currentPreview.pieceID) else {
                return
            }
            self.mapRenderer.updatePreviewNode(piece: piece, preview: currentPreview, in: self.mapRoot, worldState: self.worldState)
            if currentPreview.isValid {
                self.confirmMapPreview(keepSelection: true)
            } else {
                self.rebuildMapView()
            }
        }
    }

    func finishCurrentSelection() {
        if mapController.preview?.isValid == true {
            confirmMapPreview()
        } else {
            cancelMapPreview()
        }
    }

    func updateMapAutoPan(deltaTime: TimeInterval) {
        guard case .mapDragging(let pieceID) = gameMode,
              let screenPosition = lastMapDragScreenPosition else {
            return
        }

        let previousOffset = mapViewport.contentOffset
        let newOffset = mapViewport.autoPan(
            screenPosition: screenPosition,
            sceneSize: size,
            deltaTime: deltaTime
        )
        guard newOffset != previousOffset else {
            return
        }

        mapRenderer.applyContentOffset(newOffset, in: mapRoot)
        updatePieceDrag(at: screenPosition, pieceID: pieceID)
    }

    func cancelMapPreview() {
        mapController.cancel()
        gameMode = .mapIdle
        rebuildMapView()
    }

    func confirmMapPreview(keepSelection: Bool = false) {
        guard let preview = mapController.preview else {
            return
        }

        gameMode = .committingMapChange
        let playerSpatialBeforeCommit = playerController.state.spatialState

        guard mapController.confirm(worldState: &worldState) else {
            gameMode = .mapPieceSelected(preview.pieceID)
            rebuildMapView()
            return
        }

        AudioService.shared.playSFX("PaperMap")

        playerController.updateWorldState(worldState)
        worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)

        if let playerNode {
            if let playerSpatialBeforeCommit,
               playerSpatialBeforeCommit.pieceID == preview.pieceID {
                let didApply = playerController.apply(spatialState: playerSpatialBeforeCommit, to: playerNode)
                assert(didApply, "Player local position did not resolve back onto the moved piece.")
            } else {
                playerController.updateState(from: playerNode.position)
            }
        }

        puzzleManager.evaluate(worldState: worldState)
        if keepSelection {
            _ = mapController.select(
                pieceID: preview.pieceID,
                in: worldState,
                playerState: playerController.state,
                mapper: mapRenderer.mapper
            )
            gameMode = .mapPieceSelected(preview.pieceID)
        } else {
            gameMode = .mapIdle
        }
        rebuildMapView()
        autosave(reason: "placement confirmed")
    }

    func nodeStack(at location: CGPoint) -> [SKNode] {
        nodes(at: location).flatMap { node -> [SKNode] in
            var stack: [SKNode] = []
            var current: SKNode? = node
            while let currentNode = current {
                stack.append(currentNode)
                current = currentNode.parent
            }
            return stack
        }
    }

    func pieceID(in stack: [SKNode]) -> UUID? {
        for node in stack {
            if let pieceNode = node as? MapPieceNode {
                return pieceNode.pieceID
            }

            if let value = node.userData?[MapUserDataKey.pieceID.rawValue] as? String,
               let uuid = UUID(uuidString: value) {
                return uuid
            }
        }
        return nil
    }

    func buildingObjectID(in stack: [SKNode]) -> UUID? {
        for node in stack {
            var current: SKNode? = node
            while let n = current {
                if let value = n.userData?[BuildingObjectRenderer.objectIDKey] as? String,
                   let id = UUID(uuidString: value) {
                    return id
                }
                current = n.parent
            }
        }
        return nil
    }

    func footprintDebugTarget(in stack: [SKNode]) -> VillageSoilFootprintDebugTarget? {
        if stack.contains(where: { $0.name == MapNodeName.footprint3Button.rawValue }) {
            return .threeByThree
        }
        if stack.contains(where: { $0.name == MapNodeName.footprint6Button.rawValue }) {
            return .sixBySix
        }
        if stack.contains(where: { $0.name == MapNodeName.footprint69Button.rawValue }) {
            return .sixByNine
        }
        if stack.contains(where: { $0.name == MapNodeName.footprint915Button.rawValue }) {
            return .nineByFifteen
        }
        return nil
    }

    func currentFootprintRectangle() -> GlobalMicroRectangle? {
        guard let footprintDebugTarget else {
            return nil
        }
        let dimensions = footprintDebugTarget.dimensions
        let scanner = VillageSoilFootprintScanner()
        return scanner.findRectangleAllowingRotation(
            width: dimensions.width,
            height: dimensions.height,
            in: worldStateWithCurrentPreview()
        )
    }

    func worldStateWithCurrentPreview() -> WorldState {
        guard let preview = mapController.preview else {
            return worldState
        }
        return worldState.previewingPiece(
            id: preview.pieceID,
            at: preview.proposedPosition,
            rotation: preview.proposedRotation
        )
    }

}
