import Foundation

struct VillageQuestDialogueLine {
    let speaker: String
    let text: String
}

struct VillageQuest1Progress: Codable {
    static let saveKey = "village.carto.quest1.v5"

    var spokeToGrandpa = false
    var collectedWater = false
    var returnedHome = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest2Progress: Codable {
    static let saveKey = "village.carto.quest2.v3"

    var spokeToMara = false
    var shelfFixed = false
    var movedClayPots = false
    var acceptedKennethBasketErrand = false
    var returnedWaterToGrandpa = false
    var completed = false

    var hasBasket: Bool {
        acceptedKennethBasketErrand
    }

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

// VillageQuest3Progress is defined in VillageQuest3Models.swift

struct VillageQuest4Progress: Codable {
    static let saveKey = "village.carto.quest4.v1"

    var metAnneth = false
    var sortedTubers = false
    var receivedSaltErrand = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest5Progress: Codable {
    static let saveKey = "village.carto.quest5.v1"

    var minedSalt = false
    var heardSeaLegend = false
    var deliveredSalt = false
    var receivedSilverLeafMission = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest6Progress: Codable {
    static let saveKey = "village.carto.quest6.v1"

    var acceptedSaltErrand = false
    var pickedUpRockSalt = false
    var deliveredRockSalt = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest7Progress: Codable {
    static let saveKey = "village.carto.quest7.v1"

    var spokeToGrandpa = false
    var woodCollectedCount = 0
    var hasGatheredWood = false
    var inspectedLandslide = false
    var foundEliasBook = false
    var confrontedGrandpa = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest8Progress: Codable {
    static let saveKey = "village.carto.quest8.v1"

    var secretBaseMetFriends = false
    var convincingAttempted = false
    var convincingFailed = false
    var experiencedFog = false
    var spokeToElderInFog = false
    var annethBackyardMet = false
    var packedKnife = false
    var packedRope = false
    var packedWater = false
    var packedOintment = false
    var packedJournal = false
    var returnedToGrandpa = false
    var completed = false

    var packedCount: Int {
        var count = 0
        if packedKnife { count += 1 }
        if packedRope { count += 1 }
        if packedWater { count += 1 }
        if packedOintment { count += 1 }
        if packedJournal { count += 1 }
        return count
    }

    var allItemsPacked: Bool {
        packedCount >= 5
    }

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest9Progress: Codable {
    static let saveKey = "village.carto.quest9.v1"

    var departureChoiceMade = false
    var choseToSayGoodbye = false
    var stealthStarted = false
    var stealthCompleted = false
    var metPartyAtBoundary = false
    var inspectedRock = false
    var inspectedBark = false
    var inspectedSoil = false
    var heardForestVoices = false
    var markedTree = false
    var enteredDeepWoods = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest10Progress: Codable {
    static let saveKey = "village.carto.quest10.v1"

    var boardPrepared = false
    var sawIllusion = false
    var routeChoiceMade = false
    var choseForestGap = false
    var rolandPulledArthur = false
    var chaseCompleted = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

enum VillageQuestStage: Int, CaseIterable {
    case quest1 = 1
    case quest2
    case quest3
    case quest4
    case quest5
    case quest7
    case quest8
    case quest9
    case quest10
}

struct VillageQuestSnapshot {
    let quest1: VillageQuest1Progress
    let quest2: VillageQuest2Progress
    let quest3: VillageQuest3Progress
    let quest4: VillageQuest4Progress
    let quest5: VillageQuest5Progress
    let quest7: VillageQuest7Progress
    let quest8: VillageQuest8Progress
    let quest9: VillageQuest9Progress
    let quest10: VillageQuest10Progress
    let placedPieceIDs: Set<Int>
    let quest6RewardUnlocked: Bool
    let placedBuildingIDs: Set<String>
}

enum VillageQuestPieceRole: Equatable {
    case required
    case reserved(label: String)

    var label: String? {
        switch self {
        case .required:
            return nil
        case .reserved(let label):
            return label
        }
    }
}

struct VillageQuestUnlocks {
    let pieceOrder: [Int]
    let unlockedPieceIDs: Set<Int>
    let unlockedBuildingIDs: Set<String>
    let pieceRoles: [Int: VillageQuestPieceRole]

    func role(forPieceID id: Int) -> VillageQuestPieceRole {
        pieceRoles[id] ?? .required
    }
}

enum VillageQuestCatalog {
    static let pieceOrder = [26, 5, 20, 38, 6, 12, 8]
    static let quest10PieceOrder = [0, 1, 3]

    enum PieceID {
        static let first = 26
        static let buMaraPath = 5
        static let barnPath = 20
        static let rolandPenPath = 38
        static let annethHousePath = 6
        static let rockSaltMinePath = 6
        static let rockSaltPath = 12
        static let hollowForestReward = 8
        static let noWayHomeO = 0
        static let noWayHomeL = 1
        static let noWayHomeI = 3
    }

    enum BuildingID {
        static let arthurHouse = "arthur-house"
        static let villageWell = "village-well"
        static let buMaraHouse = "bu-mara-house"
        static let villageBarn = "village-barn"
        static let rolandPen = "roland-pen"
        static let annethHouse = "anneth-house"
        static let berynHouse = "beryn-house"
        static let emptyWarehouse = "empty-warehouse"
        static let rockSalt = "rock-salt"
    }

    enum Quest1 {
        static let mapObjectives = [
            "Place Arthur Home",
            "Place well"
        ]
        static let worldObjective = "Get water from the well for Grandpa."
    }

    enum Quest2 {
        static let mapObjective = "Help Mrs. Mara move her claypots"
        static let worldObjectives = [
            "Place Arthur Home",
            "Place well",
            "Place Mrs. Mara Home"
        ]

        static let dialogue = [
            VillageQuestDialogueLine(
                speaker: "Mrs. Mara",
                text: "Arthur! Just in time. Can you help me move these clay pots? The shelf is about to give out."
            ),
            VillageQuestDialogueLine(
                speaker: "Arthur",
                text: "The ground is sinking under this leg, Bu Mara. Moving the pots won't fix it. Let me wedge this broken brick under it."
            ),
            VillageQuestDialogueLine(
                speaker: "Mrs. Mara",
                text: "Oh, thank you! I can always count on you, Arthur. Now, since you're already here... help me lift these other two pots anyway."
            ),
            VillageQuestDialogueLine(
                speaker: "Mrs. Mara",
                text: "Also, Arthur, can you do me another favor?"
            ),
            VillageQuestDialogueLine(
                speaker: "Arthur",
                text: "Sure. What is it?"
            ),
            VillageQuestDialogueLine(
                speaker: "Mrs. Mara",
                text: "I borrowed a basket from Kenneth. Could you return it to him for me? You're going to the barn like usual, right? Kenneth should be there too, so you can give it to him while you're there."
            ),
            VillageQuestDialogueLine(
                speaker: "Arthur",
                text: "Sure, but I need to bring this water back to Grandpa first."
            )
        ]
    }

    enum Quest6 {
        static let mapObjectives = ["Place Anneth Home", "Place rock salt mine (0/3)"]
        static let worldObjective = "Pick up Rock Salt"
    }

    static func buildingID(for kind: BuildingObjectKind) -> String {
        switch kind {
        case .arthurHouse:
            return BuildingID.arthurHouse
        case .well:
            return BuildingID.villageWell
        case .buMaraHouse:
            return BuildingID.buMaraHouse
        case .barn:
            return BuildingID.villageBarn
        case .animalPen:
            return BuildingID.rolandPen
        case .annethHouse:
            return BuildingID.annethHouse
        case .rockSalt:
            return BuildingID.rockSalt
        }
    }
}
