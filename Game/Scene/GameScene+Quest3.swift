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
            showQuestDialogue(lines) { [weak self] in
                self?.showProgressionFeedback("QUEST 3 COMPLETE")
                self?.playerNode?.celebrate()
                self?.npcCharacter(named: "Kenneth")?.celebrate()
                self?.awardQuest3PieceReward()
                self?.syncVillageNPCs()
                self?.updateWorldQuestLabel()
            }

        case .alreadyCompleted(let lines):
            showQuestDialogue(lines)
            npcCharacter(named: "Kenneth")?.wave()
        }

        updateWorldQuestLabel()
    }

    // MARK: - Quest 3 Piece Reward

    func awardQuest3PieceReward() {
        let piece3UUID = BuildingPuzzleBiomeFixture.pieceUUIDs[.l1]!
        let isNewPiece = !worldState.pieces.contains(where: { $0.id == piece3UUID })

        if isNewPiece {
            let piece3 = BuildingPuzzleBiomeFixture.makePiece3()
            worldState.addPiece(piece3)

            // Update controllers dan world rendering
            playerController.updateWorldState(worldState)
            worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)
            quest3Controller.markPiece3Awarded()
            saveGameIfStable()
        }

        // Tampilkan modal perayaan hadiah kepingan peta ke-3
        showPiece3RewardCard()
    }

    func showPiece3RewardCard() {
        cameraNode.childNode(withName: "Piece3RewardModal")?.removeFromParent()

        let modal = SKNode()
        modal.name = "Piece3RewardModal"
        modal.zPosition = 20_000

        // 1. Semi-transparent backdrop
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = SKColor(white: 0, alpha: 0.45)
        backdrop.strokeColor = .clear
        modal.addChild(backdrop)

        // 2. Card Container
        let cardWidth: CGFloat = min(320, size.width - 40)
        let cardHeight: CGFloat = 190
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        card.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.14, alpha: 0.96)
        card.strokeColor = SKColor(red: 0.96, green: 0.84, blue: 0.42, alpha: 1.0)
        card.lineWidth = 2.2
        modal.addChild(card)

        // 3. Mini Header Tag
        let tag = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tag.text = "★ HADIAH QUEST 3 ★"
        tag.fontSize = 10.5
        tag.fontColor = SKColor(red: 0.98, green: 0.86, blue: 0.42, alpha: 1)
        tag.position = CGPoint(x: 0, y: 62)
        card.addChild(tag)

        // 4. Main Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Kepingan Peta ke-3 Terbuka!"
        title.fontSize = 15.5
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 40)
        card.addChild(title)

        // 5. Piece Visual Icon (Stylized Carto Mini Tile)
        let tileNode = SKNode()
        tileNode.position = CGPoint(x: 0, y: 0)
        card.addChild(tileNode)

        let tileBg = SKShapeNode(rectOf: CGSize(width: 44, height: 44), cornerRadius: 8)
        tileBg.fillColor = SKColor(red: 0.22, green: 0.42, blue: 0.25, alpha: 1.0)
        tileBg.strokeColor = SKColor(red: 0.96, green: 0.84, blue: 0.42, alpha: 0.85)
        tileBg.lineWidth = 1.5
        tileNode.addChild(tileBg)

        let tileIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tileIcon.text = "🧩"
        tileIcon.fontSize = 22
        tileIcon.verticalAlignmentMode = .center
        tileNode.addChild(tileIcon)

        // Animasi floating lembut pada icon tile
        tileNode.run(.repeatForever(.sequence([
            .scale(to: 1.10, duration: 0.6),
            .scale(to: 0.95, duration: 0.6)
        ])))

        // 6. Subtitle & Description
        let desc1 = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        desc1.text = "Potongan Jalur Hutan (Piece 3)"
        desc1.fontSize = 12
        desc1.fontColor = SKColor(red: 0.88, green: 0.92, blue: 0.84, alpha: 0.95)
        desc1.position = CGPoint(x: 0, y: -34)
        card.addChild(desc1)

        let desc2 = SKLabelNode(fontNamed: "AvenirNext-Medium")
        desc2.text = "Buka peta untuk menyambung rute ke kandang Roland!"
        desc2.fontSize = 9.5
        desc2.fontColor = SKColor(white: 0.75, alpha: 0.9)
        desc2.position = CGPoint(x: 0, y: -50)
        card.addChild(desc2)

        // 7. Tap to continue hint
        let hint = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hint.text = "Ketuk untuk melanjutkan"
        hint.fontSize = 9
        hint.fontColor = SKColor(red: 0.96, green: 0.84, blue: 0.42, alpha: 0.8)
        hint.position = CGPoint(x: 0, y: -72)
        card.addChild(hint)
        hint.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.35, duration: 0.7),
            .fadeAlpha(to: 1.0, duration: 0.7)
        ])))

        // 8. Sparkles
        let sparkles = ["✨", "⭐", "🎉", "✨", "⭐"]
        for (i, spark) in sparkles.enumerated() {
            let label = SKLabelNode(text: spark)
            label.fontSize = 13
            label.position = CGPoint(x: CGFloat(i - 2) * 44, y: 15)
            card.addChild(label)
            let dx = (CGFloat(i) - 2.0) * 22
            let dy = CGFloat(25 + i * 8)
            label.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.8),
                    .scale(to: 1.3, duration: 0.4),
                    .fadeOut(withDuration: 0.8)
                ]),
                .removeFromParent()
            ]))
        }

        cameraNode.addChild(modal)

        // Pop in animation
        card.setScale(0.7)
        card.alpha = 0
        card.run(.group([
            .fadeIn(withDuration: 0.22),
            .sequence([
                .scale(to: 1.06, duration: 0.18),
                .scale(to: 1.0, duration: 0.12)
            ])
        ]))

        // Auto dismiss after 4.5 seconds if not tapped
        modal.run(.sequence([
            .wait(forDuration: 4.5),
            .run { [weak modal] in
                modal?.run(.sequence([
                    .fadeOut(withDuration: 0.3),
                    .removeFromParent()
                ]))
            }
        ]), withKey: "autoDismiss")
    }

    // MARK: - Seed Sorting Minigame Integration

    func startQuest3SeedSortingMinigame() {
        guard activeQuestMinigame == nil else { return }

        // Hentikan pergerakan pemain selama minigame berlangsung
        if let playerNode {
            playerController.stop(playerNode: playerNode)
        }
        inputController.endTouch()

        let minigame = SeedSortingMinigameNode()
        minigame.name = "Quest3SeedSortingMinigame"
        minigame.position = .zero
        minigame.zPosition = 15_000
        cameraNode.addChild(minigame)
        activeQuestMinigame = minigame

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

        minigame.onComplete = { [weak self] in
            guard let self = self else { return }
            self.activeQuestMinigame = nil

            // Tandai minigame selesai dan tampilkan dialog penutup
            self.quest3Controller.markSeedsSorted()
            self.showQuestDialogue(VillageQuest3Catalog.postMinigameDialogue) { [weak self] in
                self?.showProgressionFeedback("QUEST 3 COMPLETE")
                self?.playerNode?.celebrate()
                self?.npcCharacter(named: "Kenneth")?.celebrate()
                self?.awardQuest3PieceReward()
                self?.syncVillageNPCs()
                self?.updateWorldQuestLabel()
            }
        }

        minigame.onDismiss = { [weak self, weak minigame] in
            if self?.activeQuestMinigame === minigame {
                self?.activeQuestMinigame = nil
            }
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
