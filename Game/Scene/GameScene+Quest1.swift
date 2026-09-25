import SpriteKit

extension GameScene {
    func mapQuestItems() -> [MapQuestItem] {
        let hasArthurHome = worldState.buildingObjects.contains { $0.kind == .arthurHouse }
        let hasWell = worldState.buildingObjects.contains { $0.kind == .well }

        guard quest1Controller.isCompleted else {
            return [
                MapQuestItem(category: "Quest 1", title: "Place Arthur Home", isCompleted: hasArthurHome),
                MapQuestItem(category: "Quest 1", title: "Place well", isCompleted: hasWell)
            ]
        }

        let placedBuildings = placedBuildingIDs()
        let quest2Progress = VillageQuest2Progress.load()
        if !quest2Progress.completed && !quest2WorldObjectivesCompleted(placedBuildings: placedBuildings) {
            return [
                MapQuestItem(
                    category: "Quest 2",
                    title: VillageQuestCatalog.Quest2.mapObjective,
                    isCompleted: false
                )
            ]
        }

        // Quest 3: Syarat Pasang Lumbung di Peta
        let quest3Progress = VillageQuest3Progress.load()
        let hasBarn = worldState.buildingObjects.contains { $0.kind == .barn }
        return [
            MapQuestItem(
                category: "Quest 3",
                title: VillageQuest3Catalog.mapObjective, // "Place Barn"
                isCompleted: quest3Progress.completed || hasBarn
            )
        ]
    }

    func quest1UnlockedObjectKinds() -> Set<BuildingObjectKind> {
        Set(BuildingObjectKind.allCases)
    }

    func placedBuildingIDs() -> Set<String> {
        Set(worldState.buildingObjects.map { VillageQuestCatalog.buildingID(for: $0.kind) })
    }

    func quest2WorldObjectivesCompleted(placedBuildings: Set<String>) -> Bool {
        placedBuildings.contains(VillageQuestCatalog.BuildingID.arthurHouse)
            && placedBuildings.contains(VillageQuestCatalog.BuildingID.villageWell)
            && placedBuildings.contains(VillageQuestCatalog.BuildingID.buMaraHouse)
    }

    func syncQuest2PlacementProgress() {
        let placedBuildings = placedBuildingIDs()
        var progress = VillageQuest2Progress.load()
        progress.completed = progress.completed || quest2WorldObjectivesCompleted(placedBuildings: placedBuildings)
        if placedBuildings.contains(VillageQuestCatalog.BuildingID.buMaraHouse) {
            progress.spokeToMara = true
        }
        progress.save()
    }

    func configureWorldQuestLabel() {
        worldQuestLabel.isHidden = true
        worldQuestTracker.position = CGPoint(x: size.width * 0.5 - 140, y: size.height * 0.5 - 112)
        worldQuestTracker.zPosition = 9_000
        worldQuestTracker.isHidden = true
    }

    func updateWorldQuestLabel() {
        if !quest1Controller.isCompleted {
            worldQuestTracker.update(with: [
                MapQuestItem(
                    category: "Quest 1",
                    title: "Get water from the well for Grandpa.",
                    isCompleted: quest1Controller.hasCollectedWater
                )
            ])
            worldQuestTracker.isHidden = gameMode != .exploring
            worldQuestLabel.isHidden = true
            return
        }

        let quest2Progress = VillageQuest2Progress.load()
        if !quest2Progress.completed {
            worldQuestTracker.update(with: [
                MapQuestItem(
                    category: "Quest 2",
                    title: VillageQuestCatalog.Quest2.mapObjective,
                    isCompleted: quest2Progress.shelfFixed
                )
            ])
            worldQuestTracker.isHidden = gameMode != .exploring
            worldQuestLabel.isHidden = true
            return
        }

        let quest3Progress = VillageQuest3Progress.load()
        if !quest3Progress.completed {
            worldQuestTracker.update(with: [
                MapQuestItem(
                    category: "Quest 3",
                    title: VillageQuest3Catalog.worldObjective, // "Deliver the basket to Keneth at the barn."
                    isCompleted: quest3Progress.sortedSeeds
                )
            ])
            worldQuestTracker.isHidden = gameMode != .exploring
            worldQuestLabel.isHidden = true
            return
        }

        worldQuestTracker.update(with: [])
        worldQuestTracker.isHidden = true
        worldQuestLabel.isHidden = true
    }

    func interactWithQuestObject(id: UUID, in stack: [SKNode]) {
        guard let object = worldState.buildingObject(id: id),
              let playerNode,
              let objectNode = stack.first(where: { $0.name == BuildingObjectRenderer.nodeName }) else {
            return
        }

        let objectPosition = objectNode.convert(CGPoint.zero, to: self)
        let distance = hypot(playerNode.position.x - objectPosition.x, playerNode.position.y - objectPosition.y)
        guard distance <= 240 else {
            showProgressionFeedback("MOVE CLOSER")
            return
        }

        switch object.kind {
        case .arthurHouse:
            let result = quest1Controller.interactWithGrandpa(in: worldState)
            handleQuest1Result(result)
        case .well:
            let result = quest1Controller.interactWithWell(in: worldState)
            handleQuest1Result(result)
        case .barn:
            handleQuest3Interaction(object: object)
        default:
            return
        }
        updateWorldQuestLabel()
    }

    private func handleQuest1Result(_ result: VillageQuest1InteractionResult) {
        switch result {
        case .unavailable(let lines), .reminder(let lines):
            showQuestDialogue(lines)
            npcCharacter(named: "Grandpa")?.wave()
        case .started(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("QUEST 1 STARTED")
            npcCharacter(named: "Grandpa")?.wave()
            syncVillageNPCs()
        case .waterCollected(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("WATER COLLECTED")
            playerNode?.celebrate()
            syncVillageNPCs()
        case .completed(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("QUEST COMPLETE")
            playerNode?.celebrate()
            npcCharacter(named: "Grandpa")?.celebrate()
            syncVillageNPCs()
        case .alreadyCompleted:
            showQuestDialogue([.init(speaker: "Grandpa", text: "Thank you again, Arthur.")])
            npcCharacter(named: "Grandpa")?.wave()
        }
    }

    func showQuestDialogue(_ lines: [VillageQuestDialogueLine], onFinished: (() -> Void)? = nil) {
        activeQuestDialogue?.removeFromParent()
        questDialogueLines = lines
        onQuestDialogueFinished = onFinished
        presentNextQuestDialogueLine()
    }

    func advanceQuestDialogue() {
        activeQuestDialogue?.popOut { [weak self] in
            self?.presentNextQuestDialogueLine()
        }
    }

    func presentNextQuestDialogueLine() {
        guard !questDialogueLines.isEmpty else {
            activeQuestDialogue = nil
            let callback = onQuestDialogueFinished
            onQuestDialogueFinished = nil
            callback?()
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
