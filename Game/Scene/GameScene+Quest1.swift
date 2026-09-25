import SpriteKit

extension GameScene {
    func mapQuestItems() -> [MapQuestItem] {
        let hasArthurHome = worldState.buildingObjects.contains { $0.kind == .arthurHouse }
        let hasWell = worldState.buildingObjects.contains { $0.kind == .well }

        if quest1Controller.isCompleted { return [] }

        return [
            MapQuestItem(category: "Quest 1", title: "Place Arthur Home", isCompleted: hasArthurHome),
            MapQuestItem(category: "Quest 1", title: "Place well", isCompleted: hasWell)
        ]
    }

    func quest1UnlockedObjectKinds() -> Set<BuildingObjectKind> {
        Set(BuildingObjectKind.allCases)
    }

    func configureWorldQuestLabel() {
        worldQuestLabel.isHidden = true
        worldQuestTracker.position = CGPoint(x: size.width * 0.5 - 140, y: size.height * 0.5 - 112)
        worldQuestTracker.zPosition = 9_000
        worldQuestTracker.isHidden = true
    }

    func updateWorldQuestLabel() {
        guard !quest1Controller.isCompleted else {
            worldQuestTracker.update(with: [])
            worldQuestTracker.isHidden = true
            worldQuestLabel.isHidden = true
            return
        }

        worldQuestTracker.update(with: [
            MapQuestItem(
                category: "Quest 1",
                title: "Get water from the well for Grandpa.",
                isCompleted: quest1Controller.hasCollectedWater
            )
        ])
        worldQuestTracker.isHidden = gameMode != .exploring
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
        guard distance <= 220 else {
            showProgressionFeedback("MOVE CLOSER")
            return
        }

        let result: VillageQuest1InteractionResult
        switch object.kind {
        case .arthurHouse:
            result = quest1Controller.interactWithGrandpa(in: worldState)
        case .well:
            result = quest1Controller.interactWithWell(in: worldState)
        default:
            return
        }

        switch result {
        case .unavailable(let lines), .reminder(let lines):
            showQuestDialogue(lines)
        case .started(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("QUEST 1 STARTED")
        case .waterCollected(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("WATER COLLECTED")
        case .completed(let lines):
            showQuestDialogue(lines)
            showProgressionFeedback("QUEST COMPLETE")
        case .alreadyCompleted:
            showQuestDialogue([.init(speaker: "Grandpa", text: "Thank you again, Arthur.")])
        }
        updateWorldQuestLabel()
    }

    func showQuestDialogue(_ lines: [VillageQuestDialogueLine]) {
        activeQuestDialogue?.removeFromParent()
        questDialogueLines = lines
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
