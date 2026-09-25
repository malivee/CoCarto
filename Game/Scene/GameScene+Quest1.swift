import SpriteKit

extension GameScene {
    func mapQuestItems() -> [MapQuestItem] {
        let hasArthurHome = worldState.buildingObjects.contains { $0.kind == .arthurHouse }
        let hasWell = worldState.buildingObjects.contains { $0.kind == .well }
        let hasMaraHome = worldState.buildingObjects.contains { $0.kind == .buMaraHouse }
        let hasBarn = worldState.buildingObjects.contains { $0.kind == .barn }
        let hasAnimalPen = worldState.buildingObjects.contains { $0.kind == .animalPen }
        let hasAnnethHome = worldState.buildingObjects.contains { $0.kind == .annethHouse }
        let rockSaltMineCount = worldState.buildingObjects.filter { $0.kind == .rockSalt }.count

        if quest5Controller.isUnlocked && !quest5Controller.isCompleted {
            return [MapQuestItem(
                category: "Quest 5",
                title: VillageQuest5Catalog.mapObjective,
                isCompleted: hasAnnethHome
            )]
        }

        if quest4Controller.isUnlocked && !quest4Controller.isCompleted {
            return [MapQuestItem(
                category: "Quest 4",
                title: VillageQuest4Catalog.mapObjective,
                isCompleted: hasAnimalPen
            )]
        }

        if !hasArthurHome {
            return [MapQuestItem(category: "Quest 1", title: VillageQuestCatalog.Quest1.mapObjectives[0], isCompleted: false)]
        }
        if !hasWell {
            return [MapQuestItem(category: "Quest 1", title: VillageQuestCatalog.Quest1.mapObjectives[1], isCompleted: false)]
        }
        if quest1Controller.hasCollectedWater && !quest2Controller.isCompleted {
            var quest2Items = [
                MapQuestItem(category: "Quest 2", title: VillageQuestCatalog.Quest2.mapObjective, isCompleted: false)
            ]
            if !hasMaraHome {
                quest2Items.append(MapQuestItem(category: "Quest 2", title: VillageQuestCatalog.Quest2.worldObjectives[2], isCompleted: false))
            }
            return quest2Items
        }
        if quest1Controller.isCompleted && quest2Controller.isCompleted && !hasBarn {
            return [MapQuestItem(category: "Quest 3", title: VillageQuest3Catalog.mapObjective, isCompleted: false)]
        }
        if quest6Controller.isUnlocked && !quest6Controller.isCompleted {
            return [
                MapQuestItem(category: "Quest 6", title: VillageQuestCatalog.Quest6.mapObjectives[0], isCompleted: hasAnnethHome),
                MapQuestItem(category: "Quest 6", title: "Place rock salt mine (\(rockSaltMineCount)/3)", isCompleted: rockSaltMineCount >= 3)
            ]
        }

        var items: [MapQuestItem] = []
        if hasArthurHome {
            items.append(MapQuestItem(category: "Quest 1", title: VillageQuestCatalog.Quest1.mapObjectives[0], isCompleted: true))
        }
        if quest1Controller.isWellUnlocked || hasWell {
            items.append(MapQuestItem(category: "Quest 1", title: VillageQuestCatalog.Quest1.mapObjectives[1], isCompleted: hasWell))
        }
        if quest1Controller.hasCollectedWater || quest2Controller.isActive || quest2Controller.isCompleted || hasMaraHome {
            items.append(MapQuestItem(category: "Quest 2", title: VillageQuestCatalog.Quest2.mapObjective, isCompleted: quest2Controller.isCompleted))
        }
        if quest1Controller.isCompleted && quest2Controller.isCompleted {
            items.append(MapQuestItem(
                category: "Quest 3",
                title: VillageQuest3Catalog.mapObjective,
                isCompleted: quest3Controller.isCompleted || hasBarn
            ))
        }
        return items
    }

    func questUnlockedObjectKinds() -> Set<BuildingObjectKind> {
        var unlocked: Set<BuildingObjectKind> = [.arthurHouse, .well]
        if quest1Controller.hasCollectedWater || quest2Controller.isActive || quest2Controller.isCompleted {
            unlocked.insert(.buMaraHouse)
        }
        if quest1Controller.isCompleted && quest2Controller.isCompleted {
            unlocked.insert(.barn)
        }
        if quest4Controller.isUnlocked {
            unlocked.insert(.animalPen)
        }
        if quest5Controller.isUnlocked {
            unlocked.insert(.annethHouse)
        }
        if quest6Controller.isUnlocked || quest6Controller.isActive {
            unlocked.insert(.annethHouse)
            unlocked.insert(.rockSalt)
        }
        return unlocked
    }

    func questUnlockedPieceRoles() -> Set<PieceRole> {
        [.z1, .z2, .l1]
    }

    @discardableResult
    func synchronizeQuestProgressionUnlocks() -> Bool {
        var didChangePieces = worldState.synchronizePuzzlePieces(allowing: questUnlockedPieceRoles())
        if worldState.setPieceMovable(quest3Controller.isCompleted, for: .z1) {
            didChangePieces = true
        }
        if didChangePieces {
            playerController.updateWorldState(worldState)
            worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)
            syncVillageNPCs()
        }
        return didChangePieces
    }

    // Placement only updates the UI. Quest 2 completes through Bu Mara's interaction and minigame.
    func syncQuest2PlacementProgress() {
        updateWorldQuestLabel()
    }

    func configureWorldQuestLabel() {
        worldQuestLabel.isHidden = true
        worldQuestTracker.position = CGPoint(x: size.width * 0.5 - 140, y: size.height * 0.5 - 112)
        worldQuestTracker.zPosition = 9_000
        worldQuestTracker.isHidden = true
    }

    func updateWorldQuestLabel() {
        if gameMode == .exploring,
           activeQuestDialogue == nil,
           let activation = quest6Controller.activateIfEligible() {
            handleQuest6Result(activation)
        }
        var items: [MapQuestItem] = []
        let hasArthurHome = worldState.buildingObjects.contains { $0.kind == .arthurHouse }
        let hasWell = worldState.buildingObjects.contains { $0.kind == .well }
        let hasMaraHome = worldState.buildingObjects.contains { $0.kind == .buMaraHouse }
        let hasBarn = worldState.buildingObjects.contains { $0.kind == .barn }

        if quest5Controller.isUnlocked && !quest5Controller.isCompleted {
            items.append(MapQuestItem(
                category: "Quest 5",
                title: VillageQuest5Catalog.worldObjective,
                isCompleted: false
            ))
            worldQuestTracker.update(with: items)
            worldQuestTracker.isHidden = gameMode != .exploring
            worldQuestLabel.isHidden = true
            return
        }

        if quest4Controller.isUnlocked && !quest4Controller.isCompleted {
            items.append(MapQuestItem(
                category: "Quest 4",
                title: VillageQuest4Catalog.worldObjective,
                isCompleted: false
            ))
            worldQuestTracker.update(with: items)
            worldQuestTracker.isHidden = gameMode != .exploring
            worldQuestLabel.isHidden = true
            return
        }

        if !quest1Controller.isCompleted {
            if !hasArthurHome {
                items.append(MapQuestItem(
                    category: "Quest 1",
                    title: VillageQuestCatalog.Quest1.mapObjectives[0],
                    isCompleted: false
                ))
            } else if !hasWell {
                items.append(MapQuestItem(
                    category: "Quest 1",
                    title: VillageQuestCatalog.Quest1.mapObjectives[1],
                    isCompleted: false
                ))
            } else if !quest1Controller.isWellUnlocked {
                items.append(MapQuestItem(
                    category: "Quest 1",
                    title: "Talk to Grandpa at Arthur Home.",
                    isCompleted: false
                ))
            } else {
                items.append(MapQuestItem(
                    category: "Quest 1",
                    title: quest1Controller.hasCollectedWater
                        ? "Return the water to Grandpa after helping Mrs. Mara."
                        : VillageQuestCatalog.Quest1.worldObjective,
                    isCompleted: false
                ))
            }
        }
        if quest1Controller.hasCollectedWater && !quest2Controller.isCompleted {
            let quest2Title: String
            if !hasArthurHome {
                quest2Title = VillageQuestCatalog.Quest2.worldObjectives[0]
            } else if !hasWell {
                quest2Title = VillageQuestCatalog.Quest2.worldObjectives[1]
            } else if !hasMaraHome {
                quest2Title = VillageQuestCatalog.Quest2.worldObjectives[2]
            } else {
                quest2Title = VillageQuestCatalog.Quest2.mapObjective
            }
            items.append(MapQuestItem(
                category: "Quest 2",
                title: quest2Title,
                isCompleted: false
            ))
        }
        if quest1Controller.isCompleted && quest2Controller.isCompleted && !quest3Controller.isCompleted {
            let quest3Progress = VillageQuest3Progress.load()
            items.append(MapQuestItem(
                category: "Quest 3",
                title: hasBarn ? VillageQuest3Catalog.worldObjective : VillageQuest3Catalog.mapObjective,
                isCompleted: quest3Progress.sortedSeeds
            ))
        }
        if quest6Controller.isActive {
            let hasAnnethHome = worldState.buildingObjects.contains { $0.kind == .annethHouse }
            let mineCount = worldState.buildingObjects.filter { $0.kind == .rockSalt }.count
            let title: String
            if !hasAnnethHome { title = VillageQuestCatalog.Quest6.mapObjectives[0] }
            else if mineCount < 3 { title = "Place rock salt mine (\(mineCount)/3)" }
            else if !quest6Controller.hasCollectedRockSalt {
                title = "Pick up Rock Salt (\(quest6Controller.collectedRockSaltCount)/3)"
            }
            else { title = "Return the Rock Salt to Mrs. Anneth" }
            items.append(MapQuestItem(category: "Quest 6", title: title, isCompleted: false))
        }
        worldQuestTracker.update(with: items)
        worldQuestTracker.isHidden = gameMode != .exploring || items.isEmpty
        worldQuestLabel.isHidden = true
    }

    func interactWithQuestObject(id: UUID, in stack: [SKNode]) {
        guard activeQuestMinigame == nil,
              let object = worldState.buildingObject(id: id),
              let playerNode,
              let objectNode = stack.first(where: { $0.name == BuildingObjectRenderer.nodeName }) else { return }
        let objectPosition = objectNode.convert(CGPoint.zero, to: self)
        let distance = hypot(playerNode.position.x - objectPosition.x, playerNode.position.y - objectPosition.y)
        guard distance <= 220 else {
            showProgressionFeedback("MOVE CLOSER")
            return
        }

        switch object.kind {
        case .arthurHouse:
            handleQuest1Result(quest1Controller.interactWithGrandpa(
                in: worldState,
                quest2Completed: quest2Controller.isCompleted
            ))
        case .well:
            handleQuest1Result(quest1Controller.interactWithWell(in: worldState))
        case .buMaraHouse:
            handleQuest2Result(quest2Controller.interactWithMara(
                in: worldState,
                hasCollectedWater: quest1Controller.hasCollectedWater
            ))
        case .barn:
            handleQuest3Interaction(object: object)
        case .animalPen:
            handleQuest4Interaction()
        case .annethHouse:
            if quest5Controller.isCompleted && quest6Controller.isActive {
                handleQuest6Result(quest6Controller.deliverToAnneth())
            } else {
                handleQuest5Interaction()
            }
        default:
            return
        }
        updateWorldQuestLabel()
    }

    func interactWithQuest6Pickup(in stack: [SKNode]) {
        guard let playerNode,
              let pickup = stack.first(where: { $0.name == BuildingObjectRenderer.quest6PickupName }),
              let mineIDString = stack.compactMap({ $0.userData?[BuildingObjectRenderer.quest6MineIDKey] as? String }).first,
              let mineID = UUID(uuidString: mineIDString) else { return }
        let pickupPosition = pickup.convert(CGPoint.zero, to: self)
        guard hypot(playerNode.position.x - pickupPosition.x, playerNode.position.y - pickupPosition.y) <= 220 else {
            showProgressionFeedback("MOVE CLOSER")
            return
        }
        handleQuest6Result(quest6Controller.collectRockSalt(from: mineID, in: worldState))
        worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)
        updateWorldQuestLabel()
    }

    func handleQuest6Result(_ result: VillageQuest6InteractionResult) {
        switch result {
        case .unavailable(let lines), .alreadyCompleted(let lines):
            showQuestDialogue(lines)
        case .activated(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("ROCK SALT MINES UNLOCKED")
        case .rockSaltCollected(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("ROCK SALT COLLECTED")
            autosave(reason: "rock salt collected")
        case .completed(let lines):
            showQuestDialogue(lines) { [weak self] in
                self?.presentToBeContinuedScreen()
            }
            showProgressionFeedback("QUEST 6 COMPLETE")
            autosave(reason: "quest 6 completed")
        }
    }

    func presentToBeContinuedScreen() {
        guard let view else { return }
        inputController.endTouch()
        let scene = ToBeContinuedScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene, transition: .fade(withDuration: 0.65))
    }

    func handleQuest1Result(_ result: VillageQuest1InteractionResult) {
        switch result {
        case .unavailable(let lines), .reminder(let lines):
            showQuestDialogue(lines)
            npcCharacter(named: "Grandpa")?.wave()
        case .started(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("WELL UNLOCKED")
            npcCharacter(named: "Grandpa")?.wave()
            synchronizeQuestProgressionUnlocks()
            syncVillageNPCs()
        case .waterCollected(let lines):
            AudioService.shared.playSFX("WellWaterPull")
            showQuestDialogue(lines)
            showProgressionFeedback("MRS. MARA HOME UNLOCKED")
            playerNode?.celebrate()
            synchronizeQuestProgressionUnlocks()
            syncVillageNPCs()
        case .completed(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("BARN UNLOCKED")
            playerNode?.celebrate()
            npcCharacter(named: "Grandpa")?.celebrate()
            synchronizeQuestProgressionUnlocks()
            syncVillageNPCs()
        case .alreadyCompleted:
            showQuestDialogue([.init(speaker: "Grandpa", text: "Thank you again, Arthur.")])
            npcCharacter(named: "Grandpa")?.wave()
        }
    }

    func handleQuest2Result(_ result: VillageQuest2InteractionResult) {
        switch result {
        case .unavailable(let lines), .reminder(let lines): showQuestDialogue(lines)
        case .started(let lines):
            showQuestDialogue(lines) { [weak self] in self?.presentMaraShelfMinigame() }
            showProgressionFeedback("QUEST 2 STARTED")
        case .needsMinigame(let lines):
            if lines.isEmpty { presentMaraShelfMinigame() }
            else { showQuestDialogue(lines) { [weak self] in self?.presentMaraShelfMinigame() } }
        case .completed(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("QUEST 2 COMPLETE")
            synchronizeQuestProgressionUnlocks()
            syncVillageNPCs()
        case .alreadyCompleted:
            showQuestDialogue([.init(speaker: "Mrs. Mara", text: "Please bring the water back to Grandpa.")])
        }
    }

    func presentMaraShelfMinigame() {
        guard activeQuestMinigame == nil else { return }
        inputController.endTouch()
        let minigame = ShelfBalanceMinigameNode()
        minigame.position = .zero
        minigame.zPosition = 15_000
        minigame.onComplete = { [weak self] succeeded in
            guard let self else { return }
            self.handleQuest2Result(self.quest2Controller.finishShelfMinigame(succeeded: succeeded))
            self.updateWorldQuestLabel()
            if succeeded { self.autosave(reason: "quest 2 completed") }
        }
        minigame.onDismiss = { [weak self, weak minigame] in
            if self?.activeQuestMinigame === minigame { self?.activeQuestMinigame = nil }
        }
        cameraNode.addChild(minigame)
        activeQuestMinigame = minigame
        minigame.start()
    }

    func showQuestDialogue(_ lines: [VillageQuestDialogueLine], onComplete: (() -> Void)? = nil) {
        activeQuestDialogue?.removeFromParent()
        questDialogueLines = lines
        onQuestDialogueFinished = onComplete
        presentNextQuestDialogueLine()
    }

    func advanceQuestDialogue() {
        activeQuestDialogue?.popOut { [weak self] in self?.presentNextQuestDialogueLine() }
    }

    func presentNextQuestDialogueLine() {
        guard !questDialogueLines.isEmpty else {
            activeQuestDialogue = nil
            let completion = onQuestDialogueFinished
            onQuestDialogueFinished = nil
            completion?()
            return
        }
        let line = questDialogueLines.removeFirst()
        let bubble = SpeechBubbleNode(config: SpeechBubbleConfig(
            text: line.text,
            speaker: line.speaker,
            pageIndicator: "Tap to continue",
            fontSize: 17,
            maxWidth: min(size.width - 72, 360)
        ))
        bubble.name = "QuestDialogue"
        bubble.position = CGPoint(x: 0, y: -size.height * 0.28)
        bubble.zPosition = 12_000
        cameraNode.addChild(bubble)
        activeQuestDialogue = bubble
        bubble.popIn()
    }
}
