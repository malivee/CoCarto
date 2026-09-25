import SpriteKit
import UIKit

// MARK: - GameScene + Quest 3 (Antarkan keranjang ke Keneth di lumbung)

extension GameScene {

    func handleQuest3Interaction(object: BuildingObject) {
        let result = quest3Controller.interactWithKenneth(in: worldState)
        switch result {
        case .unavailable(let lines):
            showQuestDialogue(lines)
            npcCharacter(named: "Kenneth")?.wave()

        case .started(let lines):
            // Mainkan dialog Arthur mengantar keranjang, Kenneth menyuruh cuci tangan & bantu gandum
            npcCharacter(named: "Kenneth")?.wave()
            showQuestDialogue(lines) { [weak self] in
                // Begitu dialog pembuka selesai (Arthur mencuci tangan), luncurkan minigame sortir gandum!
                self?.startQuest3SeedSortingMinigame()
            }
            showProgressionFeedback("QUEST 3 STARTED")

        case .minigameReady:
            startQuest3SeedSortingMinigame()

        case .completed(let lines):
            quest4Controller.handleChapter3Completed()
            synchronizeQuestProgressionUnlocks()
            showQuestDialogue(lines) { [weak self] in
                self?.showProgressionFeedback("ANIMAL PEN & TILE UNLOCKED")
                self?.playerNode?.celebrate()
                self?.npcCharacter(named: "Kenneth")?.celebrate()
                self?.syncVillageNPCs()
                self?.updateWorldQuestLabel()
            }

        case .alreadyCompleted(let lines):
            showQuestDialogue(lines)
            npcCharacter(named: "Kenneth")?.wave()
        }

        updateWorldQuestLabel()
    }

    // MARK: - Seed Sorting Minigame Integration

    func startQuest3SeedSortingMinigame() {
        // Hentikan pergerakan pemain selama minigame berlangsung
        if let playerNode {
            playerController.stop(playerNode: playerNode)
        }

        let minigame = SeedSortingMinigameNode()
        minigame.name = "Quest3SeedSortingMinigame"
        minigame.position = .zero
        minigame.zPosition = 15_000
        cameraNode.addChild(minigame)

        var dialogStage = 0
        let midDialogue = VillageQuest3Catalog.midMinigameDialogue

        // Percakapan berlanjut otomatis selama pemain memilah biji gandum di tampah
        minigame.onProgress = { [weak self, weak minigame] progress in
            guard let self = self, let minigame = minigame else { return }

            if progress >= 0.20 && dialogStage == 0 && midDialogue.count > 0 {
                dialogStage = 1
                self.showInMinigameDialogue(line: midDialogue[0], in: minigame, duration: 2.4)
            } else if progress >= 0.45 && dialogStage == 1 && midDialogue.count > 1 {
                dialogStage = 2
                self.showInMinigameDialogue(line: midDialogue[1], in: minigame, duration: 3.5)
            } else if progress >= 0.70 && dialogStage == 2 && midDialogue.count > 2 {
                dialogStage = 3
                self.showInMinigameDialogue(line: midDialogue[2], in: minigame, duration: 2.2)
            } else if progress >= 0.88 && dialogStage == 3 && midDialogue.count > 3 {
                dialogStage = 4
                self.showInMinigameDialogue(line: midDialogue[3], in: minigame, duration: 2.2)
            }
        }

        minigame.onComplete = { [weak self, weak minigame] in
            guard let self = self else { return }

            // Beri jeda halus setelah keneth membersihkan biji hitam, lalu tutup minigame
            self.run(.sequence([
                .wait(forDuration: 1.2),
                .run {
                    minigame?.run(.sequence([
                        .fadeOut(withDuration: 0.35),
                        .removeFromParent()
                    ]))

                    // Tandai minigame selesai dan tampilkan dialog penutup
                    self.quest3Controller.markSeedsSorted()
                    self.quest4Controller.handleChapter3Completed()
                    self.synchronizeQuestProgressionUnlocks()
                    self.showQuestDialogue(VillageQuest3Catalog.postMinigameDialogue) { [weak self] in
                        self?.showProgressionFeedback("ANIMAL PEN & TILE UNLOCKED")
                        self?.playerNode?.celebrate()
                        self?.npcCharacter(named: "Kenneth")?.celebrate()
                        self?.syncVillageNPCs()
                        self?.updateWorldQuestLabel()
                    }
                }
            ]))
        }

        minigame.onDismiss = { [weak minigame] in
            minigame?.run(.sequence([
                .fadeOut(withDuration: 0.25),
                .removeFromParent()
            ]))
        }

        minigame.start()
    }

    private func showInMinigameDialogue(line: VillageQuestDialogueLine, in parentNode: SKNode, duration: TimeInterval) {
        // Tampilkan gelembung bicara krayon di atas minigame
        let bubble = SpeechBubbleNode(config: SpeechBubbleConfig(
            text: line.text,
            speaker: line.speaker,
            fontName: "AvenirNext-Bold",
            fontSize: 13,
            backgroundColor: SKColor(red: 0.08, green: 0.06, blue: 0.05, alpha: 0.95),
            crayonStrokeColor: SKColor(red: 0.85, green: 0.65, blue: 0.35, alpha: 0.9),
            padding: CGSize(width: 20, height: 12),
            maxWidth: min(size.width - 60, 300)
        ))
        bubble.position = CGPoint(x: 0, y: -size.height * 0.28)
        bubble.zPosition = 200
        parentNode.addChild(bubble)
        bubble.popIn()

        bubble.run(.sequence([
            .wait(forDuration: duration),
            .run { [weak bubble] in
                bubble?.popOut {
                    bubble?.removeFromParent()
                }
            }
        ]))
    }
}
