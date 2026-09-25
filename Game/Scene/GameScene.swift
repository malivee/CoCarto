import SpriteKit
import UIKit
import CoreImage

final class GameScene: SKScene {
    private let worldRoot = SKNode()
    private let mapRoot = SKNode()
    private let worldDebugRoot = SKNode()
    private let mapDebugRoot = SKNode()
    private let cameraNode = SKCameraNode()
    private let enterMapButton = MapButtonNode(
        title: "‹ BACK",
        name: MapNodeName.enterButton.rawValue,
        size: CGSize(width: 104, height: 52),
        fontSize: 16
    )
    private let resetButton = MapButtonNode(title: "RESET", name: MapNodeName.resetButton.rawValue)
    private let saveButton = MapButtonNode(title: "SAVE", name: MapNodeName.saveButton.rawValue)
    private let loadButton = MapButtonNode(title: "LOAD", name: MapNodeName.loadButton.rawValue)

    private var worldState = WorldState.buildingPuzzleBiomePrototype
    private let mapper = WorldGridMapper(cellSize: 256)
    private lazy var worldRenderer = WorldRenderer(mapper: mapper)
    private lazy var playerController = PlayerController(mapper: mapper, worldState: worldState)
    private lazy var cameraController = CameraController(cameraNode: cameraNode)
    private lazy var debugRenderer = WorldDebugRenderer(debugRoot: worldDebugRoot)
    private let inputController = InputController()
    private let mapRenderer = MapRenderer(mapCellSize: 96)
    private let mapController = MapController()
    private var mapViewport = MapViewportController()
    private var footprintDebugTarget: VillageSoilFootprintDebugTarget?
    private var lastMapDragScreenPosition: CGPoint?
    private var inventoryLastTouchY: CGFloat?
    private var rotationInputLocked = false
    private weak var mapPinchGesture: UIPinchGestureRecognizer?
    private var pinchStartContentScale: CGFloat = 1
    private var pinchAnchorContentPoint = CGPoint.zero
    private var pinchAnchorScreenPoint = CGPoint.zero
    private let puzzleManager = PuzzleManager()
    private let worldEventManager = WorldEventManager()
    private let landmarkInteractionResolver = LandmarkInteractionResolver()
    private let transitionController = MapWorldTransitionController()
    private let saveService = try? SaveGameService()
    private let puzzleFeedbackLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let transitionFog = SKEffectNode()
    private let joystickBase = SKShapeNode(circleOfRadius: 72)
    private let joystickKnob = SKShapeNode(circleOfRadius: 28)

    private var playerNode: PlayerNode?
    private var showsDebugOverlay = false
    private var gameMode: GameMode = .exploring
    private var lastUpdateTime: TimeInterval?
    private var pendingPresentationEvents: [GameDomainEvent] = []
    private var pendingLoadedPlayerSpatialState: PlayerSpatialState?
    private var lastSaveStatus = "none"

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.09, blue: 0.10, alpha: 1)
        scaleMode = .resizeFill
        physicsWorld.gravity = .zero

        worldRoot.name = "worldRoot"
        mapRoot.name = "mapRoot"
        worldDebugRoot.name = "worldDebugRoot"
        mapDebugRoot.name = "mapDebugRoot"
        cameraNode.name = "cameraNode"

        mapRoot.isHidden = true
        mapRoot.alpha = 0
        mapRoot.zPosition = 300
        mapDebugRoot.isHidden = true
        mapDebugRoot.alpha = 0
        mapDebugRoot.zPosition = 700
        enterMapButton.zPosition = 1_000
        resetButton.zPosition = 1_000
        configurePuzzleFeedback()
        configureTransitionFog()
        configureJoystick()
        puzzleManager.onPuzzleCompleted = { [weak self] puzzleID in
            self?.handlePuzzleCompleted(puzzleID)
        }
        worldEventManager.onDomainEvent = { event in
            switch event {
            case .worldEventCompleted(let eventID):
                print("[WorldEvent] \(eventID.rawValue) completed")
            case .landmarkActivated(let landmarkID):
                print("[Consequence] \(landmarkID.rawValue) -> active")
            case .landmarkReached(let landmarkID):
                print("[Landmark] player reached \(landmarkID.rawValue)")
            case .puzzleCompleted:
                break
            }
        }

        addChild(worldRoot)
        addChild(mapRoot)
        addChild(worldDebugRoot)
        addChild(mapDebugRoot)
        addChild(resetButton)
        addChild(saveButton)
        addChild(loadButton)
        addChild(puzzleFeedbackLabel)
        addChild(cameraNode)
        cameraNode.addChild(enterMapButton)
        cameraNode.addChild(transitionFog)
        cameraNode.addChild(joystickBase)
        camera = cameraNode

        restoreSavedGameIfAvailable()
        rebuildWorldFromState()
        spawnPlayer()
        puzzleManager.evaluate(worldState: worldState)
        presentInitialMapOverview()

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleMapPinch(_:)))
        pinch.cancelsTouchesInView = true
        view.addGestureRecognizer(pinch)
        mapPinchGesture = pinch
    }

    override func willMove(from view: SKView) {
        if let mapPinchGesture {
            view.removeGestureRecognizer(mapPinchGesture)
        }
        super.willMove(from: view)
    }

    @objc private func handleMapPinch(_ gesture: UIPinchGestureRecognizer) {
        guard gameMode.isMapInteractionActive else { return }

        switch gesture.state {
        case .began:
            pinchStartContentScale = mapRenderer.contentScale
            if let spatialState = playerController.state.spatialState,
               let playerMapPosition = mapRenderer.mapMarkerPosition(
                   for: spatialState,
                   worldState: worldState,
                   preview: mapController.preview
               ) {
                pinchAnchorContentPoint = playerMapPosition
            } else {
                pinchAnchorContentPoint = .zero
            }
            pinchAnchorScreenPoint = CGPoint(
                x: pinchAnchorContentPoint.x * pinchStartContentScale + mapViewport.contentOffset.x,
                y: pinchAnchorContentPoint.y * pinchStartContentScale + mapViewport.contentOffset.y
            )
        case .changed:
            let scale = mapRenderer.setContentScale(pinchStartContentScale * gesture.scale, in: mapRoot)
            let desiredOffset = CGPoint(
                x: pinchAnchorScreenPoint.x - pinchAnchorContentPoint.x * scale,
                y: pinchAnchorScreenPoint.y - pinchAnchorContentPoint.y * scale
            )
            let offset = mapViewport.setContentOffset(desiredOffset)
            mapRenderer.applyContentOffset(offset, in: mapRoot)
        default:
            break
        }
    }

    func rebuildWorldFromState() {
        worldRenderer.buildWorld(
            from: worldState,
            into: worldRoot,
            debugRoot: worldDebugRoot,
            showsDebugLabels: showsDebugOverlay
        )
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime.map { currentTime - $0 } ?? 0
        lastUpdateTime = currentTime
        updateViewTransition(deltaTime: deltaTime)

        guard let playerNode else {
            return
        }

        switch gameMode {
        case .exploring:
            inputController.playerPosition = playerNode.position
            playerController.update(playerNode: playerNode, movementVector: inputController.movementVector)
        case .mapDragging:
            updateMapAutoPan(deltaTime: deltaTime)
            playerController.stop(playerNode: playerNode)
        case .enteringMap, .mapIdle, .mapPieceSelected, .committingMapChange, .exitingMap:
            playerController.stop(playerNode: playerNode)
        }
    }

    override func didSimulatePhysics() {
        guard let playerNode else {
            return
        }

        playerController.updateState(from: playerNode.position)
        cameraController.update(targetPosition: playerNode.position)
        layoutEnterMapButton()
        resolveLandmarkArrival(at: playerNode.position)

        if showsDebugOverlay {
            debugRenderer.update(
                playerState: playerController.state,
                worldState: worldState,
                cameraPosition: cameraNode.position,
                sceneSize: size,
                progressionText: progressionStatusText()
            )
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)
        let stack = nodeStack(at: location)
        if stack.contains(where: { $0.name == MapNodeName.resetButton.rawValue }) {
            resetPrototypePuzzle(deleteSave: true)
            return
        }
        if stack.contains(where: { $0.name == MapNodeName.saveButton.rawValue }) {
            saveGameIfStable()
            return
        }
        if stack.contains(where: { $0.name == MapNodeName.loadButton.rawValue }) {
            loadSavedGame()
            return
        }

        switch gameMode {
        case .exploring:
            if nodeStack(at: location).contains(where: { $0.name == MapNodeName.enterButton.rawValue }) {
                enterMapView()
            } else {
                let controlPosition = touch.location(in: cameraNode)
                inputController.beginTouch(at: controlPosition)
                showJoystick(at: controlPosition)
            }
        case .mapIdle, .mapPieceSelected:
            if touch.tapCount >= 2,
               let pieceID = pieceID(in: stack) {
                enterWorldByDoubleTappingTile(at: location, pieceID: pieceID)
                return
            }
            if stack.contains(where: { $0.name == MapNodeName.inventoryToggle.rawValue }) {
                mapRenderer.toggleInventory()
                rebuildMapView()
                return
            }
            if mapRenderer.inventoryExpanded,
               stack.contains(where: {
                   $0.name == MapNodeName.inventoryPanel.rawValue || $0.name == MapNodeName.inventoryItem.rawValue
               }) {
                inventoryLastTouchY = location.y
                return
            }
            handleMapTouchBegan(at: location)
        case .mapDragging:
            break
        case .enteringMap, .committingMapChange, .exitingMap:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)
        if let lastY = inventoryLastTouchY {
            mapRenderer.scrollInventory(by: location.y - lastY)
            inventoryLastTouchY = location.y
            rebuildMapView()
            return
        }
        switch gameMode {
        case .exploring:
            let controlPosition = touch.location(in: cameraNode)
            inputController.moveTouch(to: controlPosition)
            updateJoystick(to: controlPosition)
        case .mapDragging(let pieceID):
            updatePieceDrag(at: location, pieceID: pieceID)
        case .mapIdle, .mapPieceSelected:
            if mapController.interactionState == .panningMap {
                let delta = mapController.updatePan(to: location)
                _ = mapViewport.pan(by: delta)
                mapRenderer.applyContentOffset(mapViewport.contentOffset, in: mapRoot)
            }
        case .enteringMap, .committingMapChange, .exitingMap:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inventoryLastTouchY != nil {
            inventoryLastTouchY = nil
            return
        }
        switch gameMode {
        case .exploring:
            inputController.endTouch()
            hideJoystick()
            if let playerNode {
                playerController.stop(playerNode: playerNode)
            }
        case .mapDragging(let pieceID):
            finishPieceDrag(pieceID: pieceID)
        case .mapIdle, .mapPieceSelected:
            mapController.endGesture()
        case .enteringMap, .committingMapChange, .exitingMap:
            break
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func enterMapView() {
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

            let startingScale = self.cameraController.currentScale
            self.prepareMapForTransition()
            self.cameraController.beginTransitionToMap()
            self.cameraController.applyTransitionFrame(
                position: self.mapRenderer.cameraCenter,
                scale: startingScale
            )

            self.worldRoot.alpha = 0.08
            self.worldDebugRoot.alpha = 0
            self.mapRoot.alpha = 1
            self.mapDebugRoot.alpha = 1
            self.playerNode?.alpha = 0
            self.enterMapButton.alpha = 0
            self.resetButton.alpha = 0
            self.saveButton.alpha = 0
            self.loadButton.alpha = 0

            let zoomOut = SKAction.scale(to: 1.35, duration: 0.72)
            zoomOut.timingMode = .easeInEaseOut
            self.cameraNode.run(zoomOut) { [weak self] in
                guard let self, self.gameMode == .enteringMap else { return }
                self.finishWorldToMapTransition()
            }
        }
    }

    private func exitMapView() {
        guard mapController.preview == nil else {
            return
        }

        startMapToWorldTransition()
    }

    private func enterWorldByDoubleTappingTile(at _: CGPoint, pieceID: UUID) {
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

    private func rebuildMapView() {
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
            questItems: mapQuestItems()
        )
    }

    private func mapQuestItems() -> [MapQuestItem] {
        [
            MapQuestItem(
                category: "Story",
                title: "Connect the land",
                isCompleted: puzzleManager.status(for: .snowRoutePrototype) == .completed
            ),
            MapQuestItem(
                category: "Quest",
                title: "Reach the outer exit",
                isCompleted: worldEventManager.progressState.prototypeStatus == .reachedExit
            )
        ]
    }

    private func prepareMapForTransition() {
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

    private func startMapToWorldTransition() {
        guard gameMode == .mapIdle || gameMode.isMapInteractionActive || gameMode == .committingMapChange else {
            return
        }

        gameMode = .exitingMap
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

    private func presentInitialMapOverview() {
        mapController.cancel()
        prepareMapForTransition()
        transitionController.presentMapImmediately(at: mapRenderer.cameraCenter)
        cameraController.snapToMapOverview(center: mapRenderer.cameraCenter)
        finishWorldToMapTransition()
    }

    private func updateViewTransition(deltaTime: TimeInterval) {
        guard let frame = transitionController.update(deltaTime: deltaTime) else {
            return
        }

        applyTransitionFrame(frame)

        if transitionController.state == .idleMap, gameMode == .enteringMap {
            finishWorldToMapTransition()
        } else if transitionController.state == .idleWorld, gameMode == .exitingMap {
            finishMapToWorldTransition()
        }
    }

    private func applyTransitionFrame(_ frame: MapWorldTransitionFrame) {
        cameraController.applyTransitionFrame(position: frame.cameraPosition, scale: frame.cameraScale)
        worldRoot.alpha = frame.worldAlpha
        worldDebugRoot.alpha = min(frame.worldAlpha, showsDebugOverlay ? 1 : 0)
        mapRoot.alpha = frame.mapAlpha
        mapDebugRoot.alpha = frame.mapAlpha
        playerNode?.alpha = frame.playerAlpha
        enterMapButton.alpha = frame.enterMapButtonAlpha
    }

    private func finishWorldToMapTransition() {
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

    private func finishMapToWorldTransition() {
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
        flushPendingPresentationEvents()
    }

    private func handleMapTouchBegan(at location: CGPoint) {
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
            cancelMapPreview()
            return
        }

        if stack.contains(where: { $0.name == MapNodeName.confirmButton.rawValue }) {
            confirmMapPreview()
            return
        }

        if stack.contains(where: { $0.name == MapNodeName.exitButton.rawValue }) {
            exitMapView()
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
        lastMapDragScreenPosition = location
        gameMode = .mapDragging(pieceID)
        if let preview = mapController.preview,
           let piece = worldState.piece(id: preview.pieceID) {
            mapRenderer.updatePreviewNode(piece: piece, preview: preview, in: mapRoot)
        }
    }

    private func rotateSelectedPiece(clockwise: Bool) {
        guard !rotationInputLocked else { return }
        rotationInputLocked = true
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

        gameMode = .mapPieceSelected(preview.pieceID)
        mapRenderer.updatePreviewNode(
            piece: piece,
            preview: preview,
            in: mapRoot,
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

    private func updatePieceDrag(at screenPosition: CGPoint, pieceID: UUID) {
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

        mapRenderer.updatePreviewNode(piece: piece, preview: preview, in: mapRoot)
    }

    private func finishPieceDrag(pieceID: UUID) {
        lastMapDragScreenPosition = nil
        guard let preview = mapController.snapSelectedVisualToGrid(mapper: mapRenderer.mapper) else {
            gameMode = .mapIdle
            return
        }

        gameMode = .mapPieceSelected(pieceID)
        mapRenderer.animatePreviewSnap(pieceID: pieceID, to: preview.visualPosition, in: mapRoot) { [weak self] in
            guard let self,
                  let currentPreview = self.mapController.preview,
                  let piece = self.worldState.piece(id: currentPreview.pieceID) else {
                return
            }
            self.mapRenderer.updatePreviewNode(piece: piece, preview: currentPreview, in: self.mapRoot)
            self.rebuildMapView()
        }
    }

    private func finishCurrentSelection() {
        if mapController.preview?.isValid == true {
            confirmMapPreview()
        } else {
            cancelMapPreview()
        }
    }

    private func updateMapAutoPan(deltaTime: TimeInterval) {
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

    private func cancelMapPreview() {
        mapController.cancel()
        gameMode = .mapIdle
        rebuildMapView()
    }

    private func confirmMapPreview() {
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
        gameMode = .mapIdle
        rebuildMapView()
        autosave(reason: "placement confirmed")
    }

    private func nodeStack(at location: CGPoint) -> [SKNode] {
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

    private func pieceID(in stack: [SKNode]) -> UUID? {
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

    private func footprintDebugTarget(in stack: [SKNode]) -> VillageSoilFootprintDebugTarget? {
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

    private func currentFootprintRectangle() -> GlobalMicroRectangle? {
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

    private func worldStateWithCurrentPreview() -> WorldState {
        guard let preview = mapController.preview else {
            return worldState
        }
        return worldState.previewingPiece(
            id: preview.pieceID,
            at: preview.proposedPosition,
            rotation: preview.proposedRotation
        )
    }

    private func layoutEnterMapButton() {
        enterMapButton.position = CGPoint(
            x: -size.width * 0.5 + 70,
            y: size.height * 0.5 - 82
        )
        resetButton.position = CGPoint(
            x: cameraNode.position.x - size.width * 0.40,
            y: cameraNode.position.y - size.height * 0.36
        )
        saveButton.position = CGPoint(
            x: cameraNode.position.x - size.width * 0.29,
            y: cameraNode.position.y - size.height * 0.36
        )
        loadButton.position = CGPoint(
            x: cameraNode.position.x - size.width * 0.18,
            y: cameraNode.position.y - size.height * 0.36
        )
        let debugButtonAlpha: CGFloat = showsDebugOverlay && gameMode == .exploring ? 1 : 0
        resetButton.alpha = debugButtonAlpha
        saveButton.alpha = debugButtonAlpha
        loadButton.alpha = debugButtonAlpha
        puzzleFeedbackLabel.position = CGPoint(
            x: cameraNode.position.x,
            y: cameraNode.position.y + size.height * 0.30
        )
    }

    private func puzzleStatusText() -> String {
        let selectionText: String
        if let preview = mapController.preview,
           let piece = worldState.piece(id: preview.pieceID) {
            selectionText = "\nSelected: \(piece.role.debugSymbol) / \(piece.role)\npos: (\(preview.proposedPosition.x),\(preview.proposedPosition.y)) rot: \(preview.proposedRotation.rawValue) \(preview.isValid ? "VALID" : "INVALID")"
        } else {
            selectionText = "\nSelected: none"
        }
        let scanner = VillageSoilFootprintScanner()
        let largest = scanner.largestRectangle(in: worldState)
        let largestText = largest.map { "\($0.width)x\($0.height) area \($0.area)" } ?? "none"
        return "Goal: shape Village Soil for future buildings\nlargest soil rect: \(largestText)\(selectionText)"
    }

    private func progressionStatusText() -> String {
        let puzzleStatus = puzzleManager.status(for: .snowRoutePrototype)
        let eventStatus = worldEventManager.status(for: .activateOuterExit)
        let landmarkStatus = worldState.landmark(id: .outerExit)?.state ?? .inactive
        let selectedText: String
        if let preview = mapController.preview,
           let piece = worldState.piece(id: preview.pieceID) {
            selectedText = "Selected: \(piece.role.debugSymbol) / \(piece.role)\nGrid Position: (\(preview.proposedPosition.x), \(preview.proposedPosition.y))\nRotation: \(preview.proposedRotation.rawValue)\nPlacement: \(preview.isValid ? "VALID" : "INVALID")"
        } else {
            selectedText = "Selected: none"
        }
        let saveExists = saveService?.saveExists() == true ? "EXISTS" : "NONE"
        return "Mode: \(gameMode.debugLabel)\n\(selectedText)\nPuzzle: \(puzzleStatus.rawValue.uppercased())\nOuter Exit: \(landmarkStatus.rawValue.uppercased())\nWorld Event: \(eventStatus.rawValue.uppercased())\nProgress: \(worldEventManager.progressState.prototypeStatus.rawValue.uppercased())\nSave: \(saveExists) v\(SaveVersion.current)\nLast Save: \(lastSaveStatus)"
    }

    private func resetPrototypePuzzle(deleteSave: Bool) {
        inputController.endTouch()
        mapController.cancel()
        pendingPresentationEvents.removeAll()
        pendingLoadedPlayerSpatialState = nil
        worldState = .buildingPuzzleBiomePrototype
        puzzleManager.reset()
        worldEventManager.reset()
        playerController.updateWorldState(worldState)
        worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)

        if deleteSave {
            do {
                try saveService?.deleteSave()
                lastSaveStatus = "deleted"
            } catch {
                lastSaveStatus = "delete failed"
            }
        }

        if let playerNode {
            let replacement = playerController.spawnPlayerNode()
            playerNode.position = replacement.position
            playerNode.physicsBody?.velocity = .zero
            playerController.updateState(from: playerNode.position)
        }

        enterStableWorldView()
        showProgressionFeedback("RESET")
    }

    private func restoreSavedGameIfAvailable() {
        guard saveService?.saveExists() == true else {
            lastSaveStatus = "none"
            return
        }

        do {
            let saveData = try saveService?.load()
            if let saveData {
                restore(from: saveData)
                lastSaveStatus = "loaded"
            }
        } catch {
            lastSaveStatus = "load failed"
            print("[Save] load failed: \(error)")
        }
    }

    private func loadSavedGame() {
        do {
            guard let saveData = try saveService?.load() else {
                lastSaveStatus = "load unavailable"
                showProgressionFeedback("LOAD FAILED")
                return
            }
            restore(from: saveData)
            synchronizeRestoredPresentation()
            lastSaveStatus = "loaded"
            showProgressionFeedback("LOADED")
        } catch {
            lastSaveStatus = "load failed"
            print("[Save] load failed: \(error)")
            showProgressionFeedback("LOAD FAILED")
        }
    }

    private func saveGameIfStable() {
        guard gameMode == .exploring || (gameMode.isMapInteractionActive && mapController.preview == nil) else {
            lastSaveStatus = "deferred"
            return
        }

        autosave(reason: "manual")
        showProgressionFeedback(lastSaveStatus == "saved" ? "SAVED" : "SAVE FAILED")
    }

    private func autosave(reason: String) {
        guard let saveData = makeSaveData(), let saveService else {
            lastSaveStatus = "save unavailable"
            return
        }

        do {
            try saveService.save(saveData)
            lastSaveStatus = "saved"
            print("[Save] saved (\(reason)) to \(saveService.saveURL.path)")
        } catch {
            lastSaveStatus = "save failed"
            print("[Save] save failed: \(error)")
        }
    }

    private func makeSaveData() -> GameSaveData? {
        if let playerNode {
            playerController.updateState(from: playerNode.position)
        }

        guard let spatialState = playerController.state.spatialState ?? defaultPlayerSpatialState() else {
            return nil
        }

        return GameSaveData(
            worldState: worldState,
            playerState: spatialState,
            progressState: worldEventManager.progressState
        )
    }

    private func restore(from saveData: GameSaveData) {
        guard saveData.version <= SaveVersion.current else {
            lastSaveStatus = "unsupported v\(saveData.version)"
            return
        }

        worldState = saveData.worldState
        puzzleManager.restore(runtimeStates: saveData.progressState.puzzles)
        worldEventManager.restore(progressState: saveData.progressState)
        playerController.updateWorldState(worldState)
        pendingLoadedPlayerSpatialState = saveData.playerState
    }

    private func synchronizeRestoredPresentation() {
        inputController.endTouch()
        mapController.cancel()
        pendingPresentationEvents.removeAll()
        worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)

        if let playerNode {
            if let pendingLoadedPlayerSpatialState,
               playerController.apply(spatialState: pendingLoadedPlayerSpatialState, to: playerNode) {
                self.pendingLoadedPlayerSpatialState = nil
            } else {
                let replacement = playerController.spawnPlayerNode()
                playerNode.position = replacement.position
                playerNode.physicsBody?.velocity = .zero
                playerController.updateState(from: playerNode.position)
                pendingLoadedPlayerSpatialState = nil
            }
        }

        enterStableWorldView()
    }

    private func enterStableWorldView() {
        gameMode = .exploring
        mapRoot.isHidden = true
        mapDebugRoot.isHidden = true
        mapRoot.alpha = 0
        mapDebugRoot.alpha = 0
        worldRoot.isHidden = false
        worldDebugRoot.isHidden = false
        worldRoot.alpha = 1
        worldDebugRoot.alpha = showsDebugOverlay ? 1 : 0
        playerNode?.isHidden = false
        playerNode?.alpha = 1
        enterMapButton.isHidden = false
        enterMapButton.alpha = 1
        cameraController.returnToPlayerFollow()
    }

    private func defaultPlayerSpatialState() -> PlayerSpatialState? {
        guard let village = worldState.piece(role: .village),
              let cell = village.occupiedCells().sortedForSaveFallback.first else {
            return nil
        }

        let worldPosition = mapper.worldPosition(for: cell)
        let transform = PieceWorldTransform(piece: village, mapper: mapper)
        return PlayerSpatialState(
            pieceID: village.id,
            localPositionInPiece: transform.worldToLocal(worldPosition)
        )
    }

    private func configureTransitionFog() {
        transitionFog.name = "TransitionFog"
        transitionFog.zPosition = 10_000
        transitionFog.alpha = 0
        transitionFog.isHidden = true
        transitionFog.shouldRasterize = true
        transitionFog.shouldEnableEffects = true
        transitionFog.filter = CIFilter(
            name: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: 54]
        )

        let veil = SKSpriteNode(
            color: SKColor(red: 0.84, green: 0.91, blue: 0.94, alpha: 0.88),
            size: CGSize(width: size.width * 2.8, height: size.height * 2.8)
        )
        veil.name = "TransitionFogVeil"
        veil.zPosition = 0
        transitionFog.addChild(veil)

        let cloudStartPositions: [CGPoint] = [
            CGPoint(x: -size.width * 0.88, y: size.height * 0.40),
            CGPoint(x: -size.width * 0.92, y: 0),
            CGPoint(x: -size.width * 0.86, y: -size.height * 0.42),
            CGPoint(x: size.width * 0.88, y: size.height * 0.40),
            CGPoint(x: size.width * 0.92, y: 0),
            CGPoint(x: size.width * 0.86, y: -size.height * 0.42),
            CGPoint(x: -size.width * 0.38, y: size.height * 0.86),
            CGPoint(x: size.width * 0.10, y: size.height * 0.90),
            CGPoint(x: size.width * 0.42, y: size.height * 0.84),
            CGPoint(x: -size.width * 0.40, y: -size.height * 0.86),
            CGPoint(x: size.width * 0.08, y: -size.height * 0.90),
            CGPoint(x: size.width * 0.44, y: -size.height * 0.84)
        ]

        for (index, position) in cloudStartPositions.enumerated() {
            let cloudRoot = SKNode()
            cloudRoot.name = "TransitionCloud_\(index)"
            cloudRoot.position = position
            cloudRoot.zPosition = 1

            let baseRadius = max(size.width, size.height) * 0.25
            let lobeOffsets: [CGPoint] = [
                CGPoint(x: -baseRadius * 0.55, y: 0),
                CGPoint(x: 0, y: baseRadius * 0.18),
                CGPoint(x: baseRadius * 0.52, y: -baseRadius * 0.04),
                CGPoint(x: -baseRadius * 0.10, y: -baseRadius * 0.30)
            ]

            for (lobeIndex, offset) in lobeOffsets.enumerated() {
                let radius = baseRadius * (lobeIndex == 1 ? 1.08 : 0.92)
                let lobe = SKShapeNode(circleOfRadius: radius)
                lobe.position = offset
                lobe.xScale = lobeIndex.isMultiple(of: 2) ? 1.20 : 0.96
                lobe.yScale = lobeIndex.isMultiple(of: 2) ? 0.82 : 1.04
                lobe.fillColor = SKColor.white.withAlphaComponent(0.58)
                lobe.strokeColor = .clear
                cloudRoot.addChild(lobe)
            }

            transitionFog.addChild(cloudRoot)
        }
    }

    private func configureJoystick() {
        joystickBase.name = "MovementJoystickBase"
        joystickBase.fillColor = SKColor.black.withAlphaComponent(0.30)
        joystickBase.strokeColor = SKColor.white.withAlphaComponent(0.62)
        joystickBase.lineWidth = 4
        joystickBase.zPosition = 11_000
        joystickBase.alpha = 0
        joystickBase.isHidden = true
        joystickBase.addChild(joystickKnob)

        joystickKnob.name = "MovementJoystickKnob"
        joystickKnob.fillColor = SKColor.white.withAlphaComponent(0.82)
        joystickKnob.strokeColor = SKColor.white
        joystickKnob.lineWidth = 3
        joystickKnob.zPosition = 1
    }

    private func showJoystick(at position: CGPoint) {
        joystickBase.removeAllActions()
        joystickBase.position = position
        joystickKnob.position = .zero
        joystickBase.isHidden = false
        joystickBase.run(.fadeAlpha(to: 1, duration: 0.08))
    }

    private func updateJoystick(to position: CGPoint) {
        let dx = position.x - joystickBase.position.x
        let dy = position.y - joystickBase.position.y
        let distance = hypot(dx, dy)
        let maximumDistance: CGFloat = 72
        guard distance > maximumDistance else {
            joystickKnob.position = CGPoint(x: dx, y: dy)
            return
        }

        joystickKnob.position = CGPoint(
            x: dx / distance * maximumDistance,
            y: dy / distance * maximumDistance
        )
    }

    private func hideJoystick() {
        joystickBase.removeAllActions()
        joystickBase.run(.sequence([
            .fadeOut(withDuration: 0.10),
            .run { [weak self] in
                self?.joystickBase.isHidden = true
                self?.joystickKnob.position = .zero
            }
        ]))
    }

    private func playTransitionFog(onCovered: @escaping () -> Void) {
        transitionFog.removeAllActions()
        transitionFog.children.forEach { $0.removeAllActions() }
        transitionFog.isHidden = false
        transitionFog.alpha = 1
        transitionFog.setScale(1)

        let cloudStartPositions: [CGPoint] = [
            CGPoint(x: -size.width * 0.88, y: size.height * 0.40),
            CGPoint(x: -size.width * 0.92, y: 0),
            CGPoint(x: -size.width * 0.86, y: -size.height * 0.42),
            CGPoint(x: size.width * 0.88, y: size.height * 0.40),
            CGPoint(x: size.width * 0.92, y: 0),
            CGPoint(x: size.width * 0.86, y: -size.height * 0.42),
            CGPoint(x: -size.width * 0.38, y: size.height * 0.86),
            CGPoint(x: size.width * 0.10, y: size.height * 0.90),
            CGPoint(x: size.width * 0.42, y: size.height * 0.84),
            CGPoint(x: -size.width * 0.40, y: -size.height * 0.86),
            CGPoint(x: size.width * 0.08, y: -size.height * 0.90),
            CGPoint(x: size.width * 0.44, y: -size.height * 0.84)
        ]

        let cloudCenterPositions: [CGPoint] = [
            CGPoint(x: -size.width * 0.16, y: size.height * 0.18),
            CGPoint(x: -size.width * 0.18, y: 0),
            CGPoint(x: -size.width * 0.16, y: -size.height * 0.18),
            CGPoint(x: size.width * 0.16, y: size.height * 0.18),
            CGPoint(x: size.width * 0.18, y: 0),
            CGPoint(x: size.width * 0.16, y: -size.height * 0.18),
            CGPoint(x: -size.width * 0.10, y: size.height * 0.18),
            CGPoint(x: size.width * 0.02, y: size.height * 0.16),
            CGPoint(x: size.width * 0.12, y: size.height * 0.18),
            CGPoint(x: -size.width * 0.10, y: -size.height * 0.18),
            CGPoint(x: size.width * 0.02, y: -size.height * 0.16),
            CGPoint(x: size.width * 0.12, y: -size.height * 0.18)
        ]

        if let veil = transitionFog.childNode(withName: "TransitionFogVeil") {
            veil.alpha = 0
            let veilIn = SKAction.fadeAlpha(to: 1, duration: 0.48)
            veilIn.timingMode = .easeInEaseOut
            veil.run(veilIn)
        }

        for index in cloudStartPositions.indices {
            guard let cloud = transitionFog.childNode(withName: "TransitionCloud_\(index)") else {
                continue
            }

            cloud.position = cloudStartPositions[index]
            cloud.alpha = 0.28
            cloud.setScale(0.92)

            let moveIn = SKAction.move(
                to: cloudCenterPositions[index],
                duration: 0.58 + Double(index % 3) * 0.025
            )
            moveIn.timingMode = .easeInEaseOut

            let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.40)
            fadeIn.timingMode = .easeOut

            let grow = SKAction.scale(to: 1.08, duration: 0.60)
            grow.timingMode = .easeInEaseOut

            cloud.run(.group([moveIn, fadeIn, grow]))
        }

        transitionFog.run(.sequence([
            .wait(forDuration: 0.70),
            .run(onCovered),
            .wait(forDuration: 0.10),
            .run { [weak self] in
                guard let self else { return }

                if let veil = self.transitionFog.childNode(withName: "TransitionFogVeil") {
                    let veilOut = SKAction.fadeOut(withDuration: 0.58)
                    veilOut.timingMode = .easeInEaseOut
                    veil.run(veilOut)
                }

                for index in cloudStartPositions.indices {
                    guard let cloud = self.transitionFog.childNode(withName: "TransitionCloud_\(index)") else {
                        continue
                    }

                    let moveOut = SKAction.move(
                        to: cloudStartPositions[index],
                        duration: 0.58 + Double(index % 2) * 0.03
                    )
                    moveOut.timingMode = .easeInEaseOut

                    let fadeOut = SKAction.fadeOut(withDuration: 0.52)
                    fadeOut.timingMode = .easeInEaseOut

                    let shrink = SKAction.scale(to: 0.96, duration: 0.58)
                    shrink.timingMode = .easeInEaseOut

                    cloud.run(.group([moveOut, fadeOut, shrink]))
                }
            },
            .wait(forDuration: 0.64),
            .run { [weak self] in
                guard let self else { return }
                self.transitionFog.isHidden = true
                self.transitionFog.alpha = 0
            }
        ]))
    }

    private func configurePuzzleFeedback() {
        puzzleFeedbackLabel.text = ""
        puzzleFeedbackLabel.fontSize = 42
        puzzleFeedbackLabel.fontColor = .systemYellow
        puzzleFeedbackLabel.verticalAlignmentMode = .center
        puzzleFeedbackLabel.horizontalAlignmentMode = .center
        puzzleFeedbackLabel.zPosition = 1_200
        puzzleFeedbackLabel.alpha = 0
    }

    private func handlePuzzleCompleted(_ puzzleID: PuzzleID) {
        print("[Puzzle] \(puzzleID.rawValue) completed")
        worldEventManager.recordPuzzleStatus(.completed, for: puzzleID)
        queueOrPresent(.puzzleCompleted(puzzleID))
        let emittedEvents = worldEventManager.handle(.puzzleCompleted(puzzleID), worldState: &worldState)
        playerController.updateWorldState(worldState)
        worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)

        for event in emittedEvents {
            queueOrPresent(event)
        }
        autosave(reason: "puzzle completed")
    }

    private func resolveLandmarkArrival(at playerPosition: CGPoint) {
        guard gameMode == .exploring,
              worldEventManager.progressState.prototypeStatus != .reachedExit,
              let landmarkID = landmarkInteractionResolver.activeLandmarkReached(
                by: playerPosition,
                in: worldState,
                mapper: mapper
              ) else {
            return
        }

        let emittedEvents = worldEventManager.handle(.landmarkReached(landmarkID), worldState: &worldState)
        for event in emittedEvents {
            queueOrPresent(event)
        }
        autosave(reason: "landmark reached")
    }

    private func queueOrPresent(_ event: GameDomainEvent) {
        guard gameMode == .exploring else {
            pendingPresentationEvents.append(event)
            return
        }

        present(event)
    }

    private func flushPendingPresentationEvents() {
        let events = pendingPresentationEvents
        pendingPresentationEvents.removeAll()
        for event in events {
            present(event)
        }
    }

    private func present(_ event: GameDomainEvent) {
        switch event {
        case .puzzleCompleted:
            showProgressionFeedback("ROUTE COMPLETE")
        case .landmarkActivated(let landmarkID):
            if landmarkID == .outerExit {
                worldRenderer.animateLandmarkActivation(.outerExit)
            }
        case .landmarkReached(let landmarkID):
            if landmarkID == .outerExit {
                showProgressionFeedback("PROTOTYPE COMPLETE")
            }
        case .worldEventCompleted:
            break
        }
    }

    private func showProgressionFeedback(_ text: String) {
        puzzleFeedbackLabel.text = text
        puzzleFeedbackLabel.removeAllActions()
        puzzleFeedbackLabel.setScale(0.8)
        puzzleFeedbackLabel.alpha = 0
        let show = SKAction.group([
            .fadeAlpha(to: 1, duration: 0.18),
            .scale(to: 1.08, duration: 0.18)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        let wait = SKAction.wait(forDuration: 1.8)
        let hide = SKAction.fadeOut(withDuration: 0.5)
        puzzleFeedbackLabel.run(.sequence([show, settle, wait, hide]))
    }

    private func spawnPlayer() {
        let node = playerController.spawnPlayerNode()
        playerNode = node
        addChild(node)

        if let pendingLoadedPlayerSpatialState,
           playerController.apply(spatialState: pendingLoadedPlayerSpatialState, to: node) {
            self.pendingLoadedPlayerSpatialState = nil
        }

        cameraNode.position = node.position
    }
}

private extension Set where Element == GridPosition {
    var sortedForSaveFallback: [GridPosition] {
        sorted { lhs, rhs in
            if lhs.y == rhs.y {
                return lhs.x < rhs.x
            }
            return lhs.y < rhs.y
        }
    }
}
