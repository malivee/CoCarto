import Foundation

enum VillageQuest4InteractionResult {
    case unavailable([VillageQuestDialogueLine])
    case started([VillageQuestDialogueLine])
    case alreadyCompleted([VillageQuestDialogueLine])
}

final class VillageQuest4Controller {
    private(set) var progress: VillageQuest4Progress

    init(progress: VillageQuest4Progress = .load()) {
        self.progress = progress
        synchronizeChapter3Completion()
    }

    func synchronizeFromStorage() {
        progress = .load()
        synchronizeChapter3Completion()
    }

    func handleChapter3Completed() {
        guard !progress.chapter3Completed else { return }
        progress.chapter3Completed = true
        progress.save()
    }

    var isUnlocked: Bool {
        synchronizeFromStorage()
        return progress.chapter3Completed
    }

    var isCompleted: Bool {
        synchronizeFromStorage()
        return progress.completed
    }

    func isAnimalPenPlaced(in worldState: WorldState) -> Bool {
        worldState.buildingObjects.contains { $0.kind == .animalPen }
    }

    func canStart(in worldState: WorldState) -> Bool {
        isUnlocked && isAnimalPenPlaced(in: worldState) && !isCompleted
    }

    func interactWithRoland(in worldState: WorldState) -> VillageQuest4InteractionResult {
        synchronizeFromStorage()

        guard progress.chapter3Completed else {
            return .unavailable([.init(speaker: "Quest", text: "Finish Chapter 3 first.")])
        }
        guard isAnimalPenPlaced(in: worldState) else {
            return .unavailable([.init(speaker: "Quest", text: "Place the animal pen on the map first.")])
        }
        guard !progress.completed else {
            return .alreadyCompleted([
                .init(speaker: "Roland", text: "Go see Anneth at her house—and try not to climb anything on the way there.")
            ])
        }

        progress.metRoland = true
        progress.save()
        return .started(VillageQuest4Catalog.dialogue)
    }

    func completeAfterDialogue() {
        progress.metRoland = true
        progress.completed = true
        progress.save()
    }

    func reset() {
        progress = VillageQuest4Progress()
        progress.save()
    }

    private func synchronizeChapter3Completion() {
        guard VillageQuest3Progress.load().completed,
              !progress.chapter3Completed else { return }
        progress.chapter3Completed = true
        progress.save()
    }
}
