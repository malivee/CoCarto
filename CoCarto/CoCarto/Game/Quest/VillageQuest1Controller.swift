import Foundation

enum VillageQuest1InteractionResult {
    case unavailable([VillageQuestDialogueLine])
    case started([VillageQuestDialogueLine])
    case reminder([VillageQuestDialogueLine])
    case waterCollected([VillageQuestDialogueLine])
    case completed([VillageQuestDialogueLine])
    case alreadyCompleted
}

final class VillageQuest1Controller {
    private(set) var progress: VillageQuest1Progress

    init(progress: VillageQuest1Progress = .load()) {
        self.progress = progress
    }

    var isWellUnlocked: Bool {
        synchronizeFromStorage()
        return progress.spokeToGrandpa
    }
    var isActive: Bool {
        synchronizeFromStorage()
        return progress.spokeToGrandpa && !progress.returnedHome
    }
    var hasCollectedWater: Bool {
        synchronizeFromStorage()
        return progress.collectedWater
    }
    var isCompleted: Bool {
        synchronizeFromStorage()
        return progress.returnedHome
    }

    func canStart(in worldState: WorldState) -> Bool {
        synchronizeFromStorage()
        return worldState.buildingObjects.contains(where: { $0.kind == .arthurHouse })
    }

    func interactWithGrandpa(
        in worldState: WorldState,
        quest2Completed: Bool
    ) -> VillageQuest1InteractionResult {
        guard !isCompleted else { return .alreadyCompleted }

        guard canStart(in: worldState) else {
            return .unavailable([
                .init(speaker: "Quest", text: "Place Arthur Home first.")
            ])
        }

        if !progress.spokeToGrandpa {
            progress.spokeToGrandpa = true
            progress.save()
            return .started([
                .init(speaker: "Grandpa", text: "Arthur, could you fetch some water from the well? We're almost out."),
                .init(speaker: "Arthur", text: "Alright.")
            ])
        }

        guard progress.collectedWater else {
            return .reminder([
                .init(speaker: "Grandpa", text: "Please fetch some water from the well, Arthur.")
            ])
        }

        guard quest2Completed else {
            return .reminder([
                .init(speaker: "Arthur", text: "I should help Mrs. Mara before bringing the water back to Grandpa.")
            ])
        }

        progress.returnedHome = true
        progress.save()
        return .completed([
            .init(speaker: "Grandpa", text: "Did the well move farther away today? Half your water is gone."),
            .init(speaker: "Arthur", text: "Mrs. Mara's shelf almost collapsed. I had to stop and fix it."),
            .init(speaker: "Grandpa", text: "Good thing you noticed it before the well collapsed too."),
            .init(speaker: "Grandpa", text: "So, where are you off to next?"),
            .init(speaker: "Arthur", text: "The barn. I need to return this basket to Kenneth."),
            .init(speaker: "Grandpa", text: "Of course you do. You never seem to run out of things to do.")
        ])
    }

    func interactWithWell(in worldState: WorldState) -> VillageQuest1InteractionResult {
        synchronizeFromStorage()
        guard progress.spokeToGrandpa,
              worldState.buildingObjects.contains(where: { $0.kind == .arthurHouse }),
              worldState.buildingObjects.contains(where: { $0.kind == .well }) else {
            return .unavailable([
                .init(speaker: "Quest", text: "Talk to Grandpa before using the well.")
            ])
        }
        guard !progress.collectedWater else {
            return .reminder([
                .init(speaker: "Arthur", text: "I have the water. Mrs. Mara needs my help before I return to Grandpa.")
            ])
        }

        progress.collectedWater = true
        progress.save()
        return .waterCollected([
            .init(speaker: "Arthur", text: "That's enough water. I should bring it back to Grandpa.")
        ])
    }

    func reset() {
        progress = VillageQuest1Progress()
        progress.save()
    }

    private func synchronizeFromStorage() {
        progress = .load()
    }
}
