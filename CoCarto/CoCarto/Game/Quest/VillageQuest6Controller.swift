import Foundation

enum VillageQuest6InteractionResult {
    case unavailable([VillageQuestDialogueLine])
    case activated([VillageQuestDialogueLine])
    case rockSaltCollected([VillageQuestDialogueLine])
    case completed([VillageQuestDialogueLine])
    case alreadyCompleted([VillageQuestDialogueLine])
}

final class VillageQuest6Controller {
    private(set) var progress: VillageQuest6Progress

    init(progress: VillageQuest6Progress = .load()) {
        self.progress = progress
    }

    var isUnlocked: Bool { VillageQuest5Progress.load().completed }
    var isActive: Bool { synchronize(); return progress.acceptedSaltErrand && !progress.completed }
    var hasCollectedRockSalt: Bool { synchronize(); return progress.pickedUpRockSalt }
    var collectedRockSaltCount: Int { synchronize(); return progress.collectedMineIDs.count }
    var isCompleted: Bool { synchronize(); return progress.completed }

    func activateIfEligible() -> VillageQuest6InteractionResult? {
        synchronize()
        guard isUnlocked, !progress.acceptedSaltErrand else { return nil }
        progress.acceptedSaltErrand = true
        progress.save()
        return .activated(Self.introDialogue)
    }

    func collectRockSalt(from mineID: UUID, in worldState: WorldState) -> VillageQuest6InteractionResult {
        synchronize()
        if let blocker = rockSaltCollectionBlocker(from: mineID, in: worldState) {
            return .unavailable(blocker)
        }
        progress.collectedMineIDs.insert(mineID)
        progress.pickedUpRockSalt = progress.collectedMineIDs.count >= 3
        progress.save()
        if progress.pickedUpRockSalt {
            return .rockSaltCollected(Self.minerDialogue)
        }
        return .rockSaltCollected([
            .init(
                speaker: "Arthur",
                text: "Rock salt collected (\(progress.collectedMineIDs.count)/3). I need to check the other mines."
            )
        ])
    }

    func rockSaltCollectionBlocker(from mineID: UUID, in worldState: WorldState) -> [VillageQuestDialogueLine]? {
        synchronize()
        guard isUnlocked, progress.acceptedSaltErrand else {
            return [.init(speaker: "Quest", text: "Finish Anneth's previous quest first.")]
        }
        guard worldState.buildingObjects.contains(where: { $0.kind == .annethHouse }) else {
            return [.init(speaker: "Quest", text: "Place Anneth's House first.")]
        }
        let mineCount = worldState.buildingObjects.filter { $0.kind == .rockSalt }.count
        guard mineCount >= 3 else {
            return [.init(speaker: "Quest", text: "Place all three Rock Salt Mines first (\(mineCount)/3).")]
        }
        guard worldState.buildingObjects.contains(where: { $0.id == mineID && $0.kind == .rockSalt }) else {
            return [.init(speaker: "Quest", text: "This Rock Salt Mine is no longer available.")]
        }
        guard !progress.collectedMineIDs.contains(mineID) else {
            return [.init(speaker: "Arthur", text: "I already collected rock salt from this mine.")]
        }
        guard !progress.pickedUpRockSalt else {
            return [.init(speaker: "Arthur", text: "The bag is half full. I should return to Anneth.")]
        }
        return nil
    }

    func deliverToAnneth() -> VillageQuest6InteractionResult {
        synchronize()
        guard progress.pickedUpRockSalt else {
            return .unavailable([.init(speaker: "Anneth", text: "Please bring me some rock salt from the mine.")])
        }
        guard !progress.completed else {
            return .alreadyCompleted([.init(speaker: "Anneth", text: "Thank you, Arthur. Nothing will go to waste.")])
        }
        progress.deliveredRockSalt = true
        progress.completed = true
        progress.save()
        return .completed(Self.deliveryDialogue)
    }

    func reset() {
        progress = VillageQuest6Progress()
        progress.save()
    }

    private func synchronize() { progress = .load() }

    private static let introDialogue: [VillageQuestDialogueLine] = [
        .init(speaker: "Arthur", text: "That should be all of them."),
        .init(speaker: "Anneth", text: "Arthur, could you fetch some rock salt for me? I'll need more before I preserve the vegetables tomorrow."),
        .init(speaker: "Anneth", text: "Fill this old cloth bag halfway. No more than that."),
        .init(speaker: "Anneth", text: "Halfway, Arthur. And take the cart path. Don't cut through the woods."),
        .init(speaker: "Arthur", text: "Alright, alright. The road.")
    ]

    private static let minerDialogue: [VillageQuestDialogueLine] = [
        .init(speaker: "Arthur", text: "Afternoon, sir. Anneth needs some rock salt."),
        .init(speaker: "Old Miner", text: "Break some loose yourself. Take the whitest parts and leave the dark stone behind."),
        .init(speaker: "Arthur", text: "These pieces are smaller than they used to be."),
        .init(speaker: "Old Miner", text: "The easy deposits are mostly gone. We have to go deeper more often now."),
        .init(speaker: "Old Miner", text: "My father spoke of a place where the ground turns white and even the water tastes of salt."),
        .init(speaker: "Arthur", text: "Salty water? Where is this place?"),
        .init(speaker: "Old Miner", text: "If I knew, I wouldn't spend my days crawling around down here. Your bag is halfway full. Good.")
    ]

    private static let deliveryDialogue: [VillageQuestDialogueLine] = [
        .init(speaker: "Anneth", text: "Thank you, Arthur. I'll crush this right away."),
        .init(speaker: "Arthur", text: "The old miner said they have to go farther into the caves for salt now."),
        .init(speaker: "Anneth", text: "It's been that way for a while. That's why we make sure nothing goes to waste."),
        .init(speaker: "Arthur", text: "Do you think something's wrong with the soil?"),
        .init(speaker: "Anneth", text: "Maybe the earth needs time to rest. We'll know more after this season."),
        .init(speaker: "Arthur", text: "Why hasn't anyone searched for the place where the wind tastes like salt?"),
        .init(speaker: "Anneth", text: "Because people stay alive by knowing how far they can safely go. Beyond the boundaries, there are things that hunt us.")
    ]
}
