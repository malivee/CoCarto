import SpriteKit
import UIKit
import CoreImage

extension GameScene {
    func layoutEnterMapButton() {
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
        worldState = .buildingPuzzleBiomePrototype
        quest1Controller.reset()
        quest2Controller.reset()
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
