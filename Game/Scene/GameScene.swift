import SpriteKit
import UIKit
import CoreImage

final class GameScene: SKScene {
    let worldRoot = SKNode()
    let mapRoot = SKNode()
    let worldDebugRoot = SKNode()
    let mapDebugRoot = SKNode()
    let cameraNode = SKCameraNode()
    let enterMapButton = MapButtonNode(
        title: "‹ BACK",
        name: MapNodeName.enterButton.rawValue,
        size: CGSize(width: 104, height: 52),
        fontSize: 16
    )
    let resetButton = MapButtonNode(title: "RESET", name: MapNodeName.resetButton.rawValue)
    let saveButton = MapButtonNode(title: "SAVE", name: MapNodeName.saveButton.rawValue)
    let loadButton = MapButtonNode(title: "LOAD", name: MapNodeName.loadButton.rawValue)

    var worldState = WorldState.buildingPuzzleBiomePrototype(allowing: [.z1, .z2, .l1])
    let mapper = WorldGridMapper(cellSize: 256)
    lazy var worldRenderer = WorldRenderer(mapper: mapper)
    lazy var playerController = PlayerController(mapper: mapper, worldState: worldState)
    lazy var cameraController = CameraController(cameraNode: cameraNode)
    lazy var debugRenderer = WorldDebugRenderer(debugRoot: worldDebugRoot)
    let inputController = InputController()
    let mapRenderer = MapRenderer(mapCellSize: 96)
    let mapController = MapController()
    var mapViewport = MapViewportController()
    var footprintDebugTarget: VillageSoilFootprintDebugTarget?
    var lastMapDragScreenPosition: CGPoint?
    var inventoryLastTouchY: CGFloat?
    var inventoryTouchStartPosition: CGPoint?
    var inventoryTouchIndex: Int?
    var inventoryDidScroll = false
    var isDraggingObjectFromInventory = false
    var isDraggingPlacedObject = false
    var selectedObjectKind: BuildingObjectKind?
    var objectPreview: BuildingObject?
    var objectRotation: GridRotation = .degrees0
    var rotationInputLocked = false
    weak var mapPinchGesture: UIPinchGestureRecognizer?
    var pinchStartContentScale: CGFloat = 1
    var pinchAnchorContentPoint = CGPoint.zero
    var pinchAnchorScreenPoint = CGPoint.zero
    let puzzleManager = PuzzleManager()
    let worldEventManager = WorldEventManager()
    let landmarkInteractionResolver = LandmarkInteractionResolver()
    let transitionController = MapWorldTransitionController()
    let quest1Controller = VillageQuest1Controller()
    let quest2Controller = VillageQuest2Controller()
    let quest3Controller = VillageQuest3Controller()
    let quest6Controller = VillageQuest6Controller()
    let saveService = try? SaveGameService()
    let puzzleFeedbackLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let worldQuestLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    let worldQuestTracker = QuestTrackerNode()
    let transitionFog = SKEffectNode()
    let joystickBase = SKShapeNode(circleOfRadius: 72)
    let joystickKnob = SKShapeNode(circleOfRadius: 28)

    var playerNode: PlayerNode?
    var showsDebugOverlay = false
    var gameMode: GameMode = .exploring
    var lastUpdateTime: TimeInterval?
    var pendingPresentationEvents: [GameDomainEvent] = []
    var pendingLoadedPlayerSpatialState: PlayerSpatialState?
    var lastSaveStatus = "none"
    var questDialogueLines: [VillageQuestDialogueLine] = []
    weak var activeQuestDialogue: SpeechBubbleNode?
    weak var activeQuestMinigame: ShelfBalanceMinigameNode?
    var onQuestDialogueFinished: (() -> Void)?

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
        configureWorldQuestLabel()
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
        cameraNode.addChild(worldQuestLabel)
        cameraNode.addChild(worldQuestTracker)
        cameraNode.addChild(enterMapButton)
        cameraNode.addChild(transitionFog)
        cameraNode.addChild(joystickBase)
        camera = cameraNode

        restoreSavedGameIfAvailable()
        synchronizeQuestProgressionUnlocks()
        rebuildWorldFromState()
        spawnPlayer()
        puzzleManager.evaluate(worldState: worldState)
        presentInitialMapOverview()
        updateWorldQuestLabel()

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

    @objc func handleMapPinch(_ gesture: UIPinchGestureRecognizer) {
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
            if activeQuestDialogue != nil {
                advanceQuestDialogue()
                return
            }
            if nodeStack(at: location).contains(where: { $0.name == MapNodeName.enterButton.rawValue }) {
                enterMapView()
            } else if stack.contains(where: { $0.name == BuildingObjectRenderer.quest6PickupName }) {
                interactWithQuest6Pickup(in: stack)
            } else if let objectID = buildingObjectID(in: stack) {
                interactWithQuestObject(id: objectID, in: stack)
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
                inventoryTouchIndex = stack.compactMap { $0.userData?["inventoryIndex"] as? Int }.first
                inventoryTouchStartPosition = location
                inventoryDidScroll = false
                isDraggingObjectFromInventory = false
                inventoryLastTouchY = location.y
                return
            }
            if let objectID = buildingObjectID(in: stack) {
                beginPlacedObjectDrag(id: objectID, at: location)
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
            if let start = inventoryTouchStartPosition,
               let index = inventoryTouchIndex,
               let kind = mapRenderer.inventoryKind(at: index),
               location.x - start.x > 12,
               abs(location.x - start.x) > abs(location.y - start.y) {
                isDraggingObjectFromInventory = true
                inventoryLastTouchY = nil
                mapController.cancel()
                selectedObjectKind = kind
                objectRotation = .degrees0
                mapRenderer.selectInventoryItem(at: index)
                updateObjectPreview(at: location)
                return
            }
            if abs(location.y - lastY) > 2 { inventoryDidScroll = true }
            mapRenderer.scrollInventory(by: location.y - lastY)
            inventoryLastTouchY = location.y
            rebuildMapView()
            return
        }
        if isDraggingObjectFromInventory {
            updateObjectPreview(at: location)
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
        if isDraggingObjectFromInventory {
            finishObjectDrop()
            inventoryTouchIndex = nil
            inventoryTouchStartPosition = nil
            isDraggingObjectFromInventory = false
            return
        }
        if inventoryLastTouchY != nil {
            inventoryLastTouchY = nil
            if !inventoryDidScroll, let index = inventoryTouchIndex,
               let kind = mapRenderer.inventoryKind(at: index) {
                mapController.cancel()
                selectedObjectKind = kind
                objectPreview = nil
                objectRotation = .degrees0
                gameMode = .mapIdle
                mapRenderer.selectInventoryItem(at: index)
                rebuildMapView()
            }
            inventoryTouchIndex = nil
            inventoryTouchStartPosition = nil
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
        if isDraggingObjectFromInventory {
            selectedObjectKind = nil
            objectPreview = nil
            isDraggingObjectFromInventory = false
            if isDraggingPlacedObject {
                isDraggingPlacedObject = false
                worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)
                autosave(reason: "building returned to inventory")
            }
            inventoryLastTouchY = nil
            inventoryTouchStartPosition = nil
            inventoryTouchIndex = nil
            rebuildMapView()
            return
        }
        inventoryTouchIndex = nil
        inventoryTouchStartPosition = nil
        touchesEnded(touches, with: event)
    }

}
