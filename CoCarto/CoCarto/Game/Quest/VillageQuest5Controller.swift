import Foundation

enum VillageQuest5InteractionResult {
    case unavailable([VillageQuestDialogueLine])
    case started([VillageQuestDialogueLine])
    case minigameReady
    case alreadyCompleted([VillageQuestDialogueLine])
}

final class VillageQuest5Controller {
    private(set) var progress: VillageQuest5Progress

    init(progress: VillageQuest5Progress = .load()) {
        self.progress = progress
        synchronizeChapter4Completion()
    }

    func synchronizeFromStorage() {
        progress = .load()
        synchronizeChapter4Completion()
    }

    func handleChapter4Completed() {
        guard !progress.chapter4Completed else { return }
        progress.chapter4Completed = true
        progress.save()
    }

    var isUnlocked: Bool {
        synchronizeFromStorage()
        return progress.chapter4Completed
    }

    var isCompleted: Bool {
        synchronizeFromStorage()
        return progress.completed
    }

    func canStart(in worldState: WorldState) -> Bool {
        isUnlocked
            && worldState.buildingObjects.contains { $0.kind == .annethHouse }
            && !isCompleted
    }

    func interactWithAnneth(in worldState: WorldState) -> VillageQuest5InteractionResult {
        synchronizeFromStorage()
        guard progress.chapter4Completed else {
            return .unavailable([.init(speaker: "Quest", text: "Finish Quest 4 first.")])
        }
        guard worldState.buildingObjects.contains(where: { $0.kind == .annethHouse }) else {
            return .unavailable([.init(speaker: "Quest", text: "Place Anneth home on the map first.")])
        }
        guard !progress.completed else {
            return .alreadyCompleted([.init(speaker: "Anneth", text: "The clean tubers are ready to take home.")])
        }
        if progress.metAnneth {
            return .minigameReady
        }
        progress.metAnneth = true
        progress.save()
        return .started(VillageQuest5Catalog.dialogue)
    }

    func completeTubersMinigame() {
        progress.metAnneth = true
        progress.washedTubers = true
        progress.completed = true
        progress.save()
    }

    func reset() {
        progress = VillageQuest5Progress()
        progress.save()
    }

    private func synchronizeChapter4Completion() {
        guard VillageQuest4Progress.load().completed,
              !progress.chapter4Completed else { return }
        progress.chapter4Completed = true
        progress.save()
    }
}
