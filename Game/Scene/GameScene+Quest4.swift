import SpriteKit

// MARK: - GameScene + Quest 4 (Temui Roland di Kandang)

extension GameScene {
    func handleQuest4Interaction() {
        switch quest4Controller.interactWithRoland(in: worldState) {
        case .unavailable(let lines):
            showQuestDialogue(lines)

        case .started(let lines):
            npcCharacter(named: "Roland")?.wave()
            showQuestDialogue(lines) { [weak self] in
                guard let self else { return }
                self.quest4Controller.completeAfterDialogue()
                self.quest5Controller.handleChapter4Completed()
                self.showProgressionFeedback("QUEST 4 COMPLETE")
                self.playerNode?.celebrate()
                self.npcCharacter(named: "Roland")?.celebrate()
                self.syncVillageNPCs()
                self.updateWorldQuestLabel()
                self.autosave(reason: "quest 4 completed")
            }
            showProgressionFeedback("QUEST 4 STARTED")

        case .alreadyCompleted(let lines):
            showQuestDialogue(lines)
            npcCharacter(named: "Roland")?.wave()
        }

        updateWorldQuestLabel()
    }
}
