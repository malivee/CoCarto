import Foundation

// MARK: - Quest 3 Interaction Result

enum VillageQuest3InteractionResult {
    case unavailable([VillageQuestDialogueLine])
    case started([VillageQuestDialogueLine])
    case minigameReady
    case completed([VillageQuestDialogueLine])
    case alreadyCompleted([VillageQuestDialogueLine])
}

// MARK: - Quest 3 Controller

final class VillageQuest3Controller {
    private(set) var progress: VillageQuest3Progress

    init(progress: VillageQuest3Progress = .load()) {
        self.progress = progress
    }

    func synchronizeFromStorage() {
        self.progress = .load()
    }

    // Trigger: Terbuka setelah menyelesaikan Chapter 1 dan Chapter 2
    var isUnlocked: Bool {
        let q1 = VillageQuest1Progress.load()
        let q2 = VillageQuest2Progress.load()
        return q1.returnedHome && q2.completed
    }

    var isBarnUnlocked: Bool {
        isUnlocked
    }

    var isCompleted: Bool {
        synchronizeFromStorage()
        return progress.completed
    }

    var isWaitingForMinigame: Bool {
        synchronizeFromStorage()
        return progress.deliveredBasket && progress.washedHands && !progress.sortedSeeds
    }

    // Syarat: Pasang Lumbung di peta
    func isBarnPlaced(in worldState: WorldState) -> Bool {
        worldState.buildingObjects.contains(where: { $0.kind == .barn })
    }

    func canStart(in worldState: WorldState) -> Bool {
        isUnlocked && isBarnPlaced(in: worldState)
    }

    func interactWithKenneth(in worldState: WorldState) -> VillageQuest3InteractionResult {
        synchronizeFromStorage()

        guard !progress.completed else {
            return .alreadyCompleted([
                VillageQuestDialogueLine(speaker: "Kenneth", text: "Roland is at the animal pens. Go bother him.")
            ])
        }

        guard isUnlocked else {
            return .unavailable([
                VillageQuestDialogueLine(speaker: "Quest", text: "Finish Grandpa and Mrs. Mara's quests first.")
            ])
        }

        // Cek syarat pemasangan lumbung
        guard isBarnPlaced(in: worldState) else {
            return .unavailable([
                VillageQuestDialogueLine(speaker: "Quest", text: "Place the Barn on the map first.")
            ])
        }

        // Tahap 1: Belum mengantar keranjang / belum cuci tangan
        if !progress.deliveredBasket {
            progress.deliveredBasket = true
            progress.washedHands = true
            progress.save()
            return .started(VillageQuest3Catalog.preMinigameDialogue)
        }

        // Tahap 2: Siap memulai minigame sortir biji gandum
        if !progress.sortedSeeds {
            return .minigameReady
        }

        // Tahap 3: Minigame selesai -> Dialog penutup dan penyelesaian Quest 3
        progress.completed = true
        progress.save()
        return .completed(VillageQuest3Catalog.postMinigameDialogue)
    }

    func markSeedsSorted() {
        progress.sortedSeeds = true
        progress.completed = true
        progress.save()
    }

    func reset() {
        progress = VillageQuest3Progress()
        progress.save()
    }
}
