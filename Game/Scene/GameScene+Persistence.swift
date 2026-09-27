import SpriteKit
import UIKit
import CoreImage

extension GameScene {
    func layoutEnterMapButton() {
        let safeInsets = view?.safeAreaInsets ?? .zero
        let hudScale: CGFloat = 0.82
        worldMinimap.setScale(hudScale)
        worldMinimap.position = CGPoint(
            x: -size.width / 2 + safeInsets.left + 16 + 92 * hudScale,
            y: size.height / 2 - safeInsets.top - 16 - 87 * hudScale
        )
        let canReturnToMap = !isQuest1TutorialActive
        enterMapButton.isHidden = !canReturnToMap
        worldMinimap.setNavigationEnabled(canReturnToMap)
        layoutWorldObjectiveCards()
        worldMinimap.isHidden = gameMode != .exploring
        if !worldMinimap.isHidden {
            worldMinimap.update(worldState: worldState, playerState: playerController.state,
                                playerPosition: playerNode?.position ?? .zero, mapper: mapper)
        }
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

    func layoutWorldObjectiveCards() {
        let insets = view?.safeAreaInsets ?? .zero
        let rightEdge = size.width / 2 - insets.right - 16
        let minimapRight = worldMinimap.position.x + 92 * worldMinimap.xScale
        let cardWidth = min(size.width - 56, 410)
        let besideMinimap = rightEdge - minimapRight - 16 >= cardWidth
        let top = worldMinimap.position.y + 87 * worldMinimap.yScale
        let cardTop = besideMinimap ? top : worldMinimap.position.y - worldMinimap.bottomExtent * worldMinimap.yScale - 12
        let centerX = besideMinimap ? rightEdge - cardWidth / 2 : 0
        worldTutorialBanner.position = CGPoint(x: centerX, y: cardTop - 41)
        worldQuestTracker.position = CGPoint(x: besideMinimap ? rightEdge - 126 : 0, y: cardTop - 56)
    }

    func puzzleStatusText() -> String {
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

    func progressionStatusText() -> String {
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

    func resetPrototypePuzzle(deleteSave: Bool) {
        inputController.endTouch()
        mapController.cancel()
        pendingPresentationEvents.removeAll()
        pendingLoadedPlayerSpatialState = nil
        selectedObjectKind = nil
        objectPreview = nil
        hasMovedArthurInTutorial = false
        hasRotatedTileInTutorial = false
        hasRotatedPieceInTutorial = false
        hasTriedMismatchedTileInTutorial = false
        tutorialInvalidBuildingKinds.removeAll()
        worldState = .buildingPuzzleBiomePrototype(allowing: [.z2, .l1])
        quest1Controller.reset()
        quest2Controller.reset()
        quest3Controller.reset()
        quest4Controller.reset()
        quest5Controller.reset()
        quest6Controller.reset()
        mapRenderer.resetSeenInventoryKinds()
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

    func restoreSavedGameIfAvailable() {
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

    func loadSavedGame() {
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

    func saveGameIfStable() {
        guard gameMode == .exploring || (gameMode.isMapInteractionActive && mapController.preview == nil) else {
            lastSaveStatus = "deferred"
            return
        }

        autosave(reason: "manual")
        showProgressionFeedback(lastSaveStatus == "saved" ? "SAVED" : "SAVE FAILED")
    }

    func autosave(reason: String) {
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

    func makeSaveData() -> GameSaveData? {
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

    func restore(from saveData: GameSaveData) {
        guard saveData.version <= SaveVersion.current else {
            lastSaveStatus = "unsupported v\(saveData.version)"
            return
        }

        selectedObjectKind = nil
        objectPreview = nil
        worldState = saveData.worldState
        puzzleManager.restore(runtimeStates: saveData.progressState.puzzles)
        worldEventManager.restore(progressState: saveData.progressState)
        playerController.updateWorldState(worldState)
        pendingLoadedPlayerSpatialState = saveData.playerState
    }

    func synchronizeRestoredPresentation() {
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

    func enterStableWorldView() {
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
        updateWorldQuestLabel()
    }

    func defaultPlayerSpatialState() -> PlayerSpatialState? {
        guard let spawnPiece = worldState.piece(role: .village) ?? worldState.piece(role: .z2),
              let cell = spawnPiece.occupiedCells().sortedForSaveFallback.first else {
            return nil
        }

        let worldPosition = mapper.worldPosition(for: cell)
        let transform = PieceWorldTransform(piece: spawnPiece, mapper: mapper)
        return PlayerSpatialState(
            pieceID: spawnPiece.id,
            localPositionInPiece: transform.worldToLocal(worldPosition)
        )
    }

}

/// Camera HUD: geometry is rebuilt only after the world or connected area changes.
final class WorldMinimapNode: SKNode {
    private let terrain = SKNode()
    private let panel = SKShapeNode()
    private let shadow = SKShapeNode()
    private let separator = SKShapeNode()
    private(set) var bottomExtent: CGFloat = 87
    private var navigationEnabled: Bool?
    private let marker = SKShapeNode(circleOfRadius: 3.5)
    private var cachedPieces: [WorldPiece] = []
    private var cachedBuildings: [BuildingObject] = []
    private var cachedCell: GridPosition?
    private var visibleCells = Set<GridPosition>()
    private var minimapBounds = CGRect.zero
    private var mapScale: CGFloat = 1

    override init() {
        super.init()
        name = MapNodeName.enterButton.rawValue
        zPosition = 1_000
        shadow.path = CGPath(roundedRect: CGRect(x: -92, y: -87, width: 184, height: 174), cornerWidth: 18, cornerHeight: 18, transform: nil)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position.y = -3
        addChild(shadow)
        panel.path = shadow.path
        panel.fillColor = SKColor(red: 0.04, green: 0.12, blue: 0.16, alpha: 0.94)
        panel.strokeColor = SKColor.white.withAlphaComponent(0.3)
        panel.lineWidth = 1
        addChild(panel)
        let heading = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        heading.text = "YOUR SURROUNDINGS"
        heading.fontSize = 9
        heading.fontColor = SKColor(red: 0.87, green: 0.83, blue: 0.68, alpha: 1)
        heading.position = CGPoint(x: -76, y: 69)
        heading.horizontalAlignmentMode = .left
        addChild(heading)
        let north = SKLabelNode(fontNamed: "AvenirNext-Bold")
        north.text = "N ↑"
        north.fontSize = 9
        north.fontColor = .white
        north.position = CGPoint(x: 76, y: 69)
        north.horizontalAlignmentMode = .right
        addChild(north)
        separator.path = CGPath(rect: CGRect(x: -76, y: -0.5, width: 152, height: 1), transform: nil)
        separator.fillColor = SKColor.white.withAlphaComponent(0.12)
        separator.strokeColor = .clear
        separator.position.y = -28
        addChild(separator)
        terrain.position.y = 20
        addChild(terrain)
        marker.fillColor = .white
        marker.strokeColor = .systemBlue
        marker.lineWidth = 2
        marker.zPosition = 10
        terrain.addChild(marker)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setNavigationEnabled(_ enabled: Bool) {
        guard navigationEnabled != enabled else { return }
        navigationEnabled = enabled
        name = enabled ? MapNodeName.enterButton.rawValue : "WorldMinimap"
        bottomExtent = enabled ? 87 : 30
        let frame = CGRect(x: -92, y: -bottomExtent, width: 184, height: 87 + bottomExtent)
        panel.path = CGPath(roundedRect: frame, cornerWidth: 18, cornerHeight: 18, transform: nil)
        shadow.path = panel.path
        separator.isHidden = !enabled
    }

    func update(worldState: WorldState, playerState: PlayerState, playerPosition: CGPoint, mapper: WorldGridMapper) {
        let changed = cachedPieces != worldState.pieces || cachedBuildings != worldState.buildingObjects
        if changed || cachedCell != playerState.currentCell {
            let cells = ConnectedComponentResolver().reachableCells(from: playerState, in: worldState)
            if changed || cells != visibleCells {
                visibleCells = cells
                rebuild(worldState: worldState, mapper: mapper)
            }
            cachedPieces = worldState.pieces
            cachedBuildings = worldState.buildingObjects
            cachedCell = playerState.currentCell
        }
        marker.isHidden = visibleCells.isEmpty
        marker.position = point(playerPosition)
    }

    private func point(_ position: CGPoint) -> CGPoint {
        CGPoint(x: (position.x - minimapBounds.midX) * mapScale, y: (position.y - minimapBounds.midY) * mapScale)
    }

    private func rebuild(worldState: WorldState, mapper: WorldGridMapper) {
        terrain.children.filter { $0 !== marker }.forEach { $0.removeFromParent() }
        guard !visibleCells.isEmpty else { return }
        minimapBounds = visibleCells.reduce(CGRect.null) { $0.union(mapper.frame(for: $1)) }
        mapScale = min(148 / minimapBounds.width, 80 / minimapBounds.height)
        let miniatureMapper = WorldGridMapper(cellSize: mapper.cellSize * mapScale)
        for piece in worldState.pieces {
            let resolvedCells = Dictionary(uniqueKeysWithValues: piece.resolvedCells().map { ($0.gridID, $0) })
            for cell in piece.cellDefinitions {
                guard let resolved = resolvedCells[cell.id],
                      visibleCells.contains(resolved.globalPosition) else { continue }
                // Reuse the world tile renderer for assets, biome splits and mirroring.
                let tile = CellNode(
                    gridID: cell.id, localCell: .init(x: 0, y: 0),
                    globalCell: resolved.globalPosition, biomeEdges: cell.biomeEdges,
                    microBiomeGrid: cell.microBiomeGrid, piece: piece,
                    mapper: miniatureMapper, showsDebugLabels: false
                )
                tile.position = point(mapper.worldPosition(for: resolved.globalPosition))
                tile.zRotation = piece.rotation.radians
                terrain.addChild(tile)
            }
        }
        let microSize = mapper.cellSize / CGFloat(MicroBiomeGrid.dimension)
        for building in worldState.buildingObjects {
            let dimensions = building.mapDimensions
            let center = CGPoint(x: (CGFloat(building.origin.x) + CGFloat(dimensions.width) / 2) * microSize - mapper.halfCellSize,
                                 y: (CGFloat(building.origin.y) + CGFloat(dimensions.height) / 2) * microSize - mapper.halfCellSize)
            guard visibleCells.contains(mapper.gridPosition(containing: center)) else { continue }
            let icon: SKSpriteNode
            if let asset = BuildingObjectRenderer.assetName(for: building.kind) {
                icon = SKSpriteNode(imageNamed: asset)
            } else {
                icon = SKSpriteNode(color: .systemOrange, size: CGSize(width: 10, height: 10))
            }
            let width = max(8, CGFloat(dimensions.width) * microSize * mapScale)
            let height = max(8, CGFloat(dimensions.height) * microSize * mapScale)
            let quarterTurn = building.rotation == .degrees90 || building.rotation == .degrees270
            icon.size = quarterTurn ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
            icon.zRotation = building.rotation.radians
            icon.position = point(center)
            icon.zPosition = 2
            terrain.addChild(icon)
        }
    }
}
