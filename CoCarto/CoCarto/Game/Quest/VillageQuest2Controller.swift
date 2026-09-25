import Foundation

enum VillageQuest2InteractionResult {
    case unavailable([VillageQuestDialogueLine])
    case started([VillageQuestDialogueLine])
    case reminder([VillageQuestDialogueLine])
    case needsMinigame([VillageQuestDialogueLine])
    case completed([VillageQuestDialogueLine])
    case alreadyCompleted
}

final class VillageQuest2Controller {
    private(set) var progress: VillageQuest2Progress

    init(progress: VillageQuest2Progress = .load()) {
        self.progress = progress
    }

    var isActive: Bool {
        synchronizeFromStorage()
        return progress.spokeToMara && !progress.completed
    }

    var isCompleted: Bool {
        synchronizeFromStorage()
        return progress.completed
    }

    func interactWithMara(
        in worldState: WorldState,
        hasCollectedWater: Bool
    ) -> VillageQuest2InteractionResult {
        synchronizeFromStorage()

        guard hasCollectedWater else {
            return .unavailable([
                .init(speaker: "Quest", text: "Get water from the well first.")
            ])
        }

        guard worldState.buildingObjects.contains(where: { $0.kind == .arthurHouse }),
              worldState.buildingObjects.contains(where: { $0.kind == .buMaraHouse }) else {
            return .unavailable([
                .init(speaker: "Quest", text: "Place Arthur Home and Mrs. Mara Home first.")
            ])
        }

        guard !progress.completed else { return .alreadyCompleted }

        if !progress.spokeToMara {
            progress.spokeToMara = true
            progress.save()
            return .started(Array(VillageQuestCatalog.Quest2.dialogue.prefix(2)))
        }

        guard !progress.shelfFixed else {
            return .reminder([
                .init(speaker: "Mrs. Mara", text: "Thank you again, Arthur. Please bring the water back to Grandpa.")
            ])
        }

        return .needsMinigame([])
    }

    func finishShelfMinigame(succeeded: Bool) -> VillageQuest2InteractionResult {
        synchronizeFromStorage()
        guard progress.spokeToMara, !progress.completed else {
            return progress.completed ? .alreadyCompleted : .unavailable([])
        }

        guard succeeded else {
            return .reminder([
                .init(speaker: "Arthur", text: "I need to try fixing Mrs. Mara's shelf again.")
            ])
        }

        progress.shelfFixed = true
        progress.movedClayPots = true
        progress.acceptedKennethBasketErrand = true
        progress.completed = true
        progress.save()
        return .completed(Array(VillageQuestCatalog.Quest2.dialogue.dropFirst(2)))
    }

    func reset() {
        progress = VillageQuest2Progress()
        progress.save()
    }

    private func synchronizeFromStorage() {
        progress = .load()
    }
}
