import SpriteKit

extension GameScene {
    func mapQuestItems() -> [MapQuestItem] {
        let hasArthurHome = worldState.buildingObjects.contains { $0.kind == .arthurHouse }
        let hasWell = worldState.buildingObjects.contains { $0.kind == .well }
        let hasMaraHome = worldState.buildingObjects.contains { $0.kind == .buMaraHouse }
        var items = [
            MapQuestItem(category: "Quest 1", title: VillageQuestCatalog.Quest1.mapObjectives[0], isCompleted: hasArthurHome),
            MapQuestItem(category: "Quest 1", title: VillageQuestCatalog.Quest1.mapObjectives[1], isCompleted: hasWell)
        ]
        if quest1Controller.hasCollectedWater || quest2Controller.isActive || quest2Controller.isCompleted {
            items.append(MapQuestItem(category: "Quest 2", title: "Place Mrs. Mara Home", isCompleted: hasMaraHome))
        }
        return items
    }

    func quest1UnlockedObjectKinds() -> Set<BuildingObjectKind> {
        var unlocked: Set<BuildingObjectKind> = [.arthurHouse, .well]
        if quest1Controller.hasCollectedWater { unlocked.insert(.buMaraHouse) }
        if quest1Controller.isCompleted { unlocked.formUnion(BuildingObjectKind.allCases) }
        return unlocked
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
        var items: [MapQuestItem] = []
        if !quest1Controller.isCompleted {
            let hasWell = worldState.buildingObjects.contains { $0.kind == .well }
            items.append(MapQuestItem(
                category: "Quest 1",
                title: VillageQuestCatalog.Quest1.mapObjectives[1],
                isCompleted: hasWell
            ))
            items.append(MapQuestItem(
                category: "Quest 1",
                title: quest1Controller.hasCollectedWater
                    ? "Return the water to Grandpa after helping Mrs. Mara."
                    : VillageQuestCatalog.Quest1.worldObjective,
                isCompleted: false
            ))
        }
        if quest1Controller.hasCollectedWater && !quest2Controller.isCompleted {
            items.append(MapQuestItem(
                category: "Quest 2",
                title: VillageQuestCatalog.Quest2.mapObjective,
                isCompleted: false
            ))
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
        default:
            return
        }
        updateWorldQuestLabel()
    }

    func handleQuest1Result(_ result: VillageQuest1InteractionResult) {
        switch result {
        case .unavailable(let lines), .reminder(let lines): showQuestDialogue(lines)
        case .started(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("QUEST 1 STARTED")
        case .waterCollected(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("QUEST 2 UNLOCKED")
        case .completed(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("QUEST 1 COMPLETE")
        case .alreadyCompleted:
            showQuestDialogue([.init(speaker: "Grandpa", text: "Thank you again, Arthur.")])
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
        questDialogueCompletion = onComplete
        presentNextQuestDialogueLine()
    }

    func advanceQuestDialogue() {
        activeQuestDialogue?.popOut { [weak self] in self?.presentNextQuestDialogueLine() }
    }

    func presentNextQuestDialogueLine() {
        guard !questDialogueLines.isEmpty else {
            activeQuestDialogue = nil
            let completion = questDialogueCompletion
            questDialogueCompletion = nil
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
