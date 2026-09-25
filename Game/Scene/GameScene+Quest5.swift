import SpriteKit

extension GameScene {
    func handleQuest5Interaction() {
        switch quest5Controller.interactWithAnneth(in: worldState) {
        case .unavailable(let lines):
            showQuestDialogue(lines)

        case .started(let lines):
            npcCharacter(named: "Anneth")?.wave()
            showQuestDialogue(lines) { [weak self] in
                self?.startQuest5TubersMinigame()
            }
            showProgressionFeedback("QUEST 5 STARTED")

        case .minigameReady:
            startQuest5TubersMinigame()

        case .alreadyCompleted(let lines):
            showQuestDialogue(lines)
            npcCharacter(named: "Anneth")?.wave()
        }
        updateWorldQuestLabel()
    }

    func startQuest5TubersMinigame() {
        guard activeQuestMinigame == nil else { return }
        if let playerNode {
            playerController.stop(playerNode: playerNode)
        }

        let minigame = ItemSortingMinigameNode(config: ItemSortingConfig(requiredItems: 6))
        minigame.name = "Quest5TubersMinigame"
        minigame.position = .zero
        minigame.zPosition = 15_000
        minigame.onComplete = { [weak self] succeeded in
            guard let self, succeeded else { return }
            self.quest5Controller.completeTubersMinigame()
            self.showProgressionFeedback("QUEST 5 COMPLETE")
            self.playerNode?.celebrate()
            self.npcCharacter(named: "Anneth")?.celebrate()
            self.syncVillageNPCs()
            self.updateWorldQuestLabel()
            self.autosave(reason: "quest 5 completed")
        }
        minigame.onDismiss = { [weak self, weak minigame] in
            if self?.activeQuestMinigame === minigame {
                self?.activeQuestMinigame = nil
            }
        }
        cameraNode.addChild(minigame)
        activeQuestMinigame = minigame
        minigame.start()
    }
}
