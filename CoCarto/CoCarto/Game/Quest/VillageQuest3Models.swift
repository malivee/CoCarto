import Foundation

// MARK: - Quest 3 Models & Progress

struct VillageQuest3Progress: Codable, Sendable {
    static let saveKey = "village.carto.quest3.v3"

    var deliveredBasket: Bool = false
    var washedHands: Bool = false
    var sortedSeeds: Bool = false
    var completed: Bool = false
    var piece3Awarded: Bool = false

    init(
        deliveredBasket: Bool = false,
        washedHands: Bool = false,
        sortedSeeds: Bool = false,
        completed: Bool = false,
        piece3Awarded: Bool = false
    ) {
        self.deliveredBasket = deliveredBasket
        self.washedHands = washedHands
        self.sortedSeeds = sortedSeeds
        self.completed = completed
        self.piece3Awarded = piece3Awarded
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

// MARK: - Quest 3 Catalog & Story Content

enum VillageQuest3Catalog {
    static let questNumber: Int = 3
    static let title: String = "Quest 3 - Antarkan keranjang ke Keneth di lumbung"
    static let triggerDescription: String = "Setelah menyelesaikan chapter satu dan dua"
    static let unlockItem: String = "Lumbung"
    static let requirement: String = "Pasang Lumbung"
    static let mapObjective: String = "Place Barn"
    static let worldObjective: String = "Deliver the basket to Keneth at the barn."

    // 1. Dialog sebelum minigame (Arthur mengantar keranjang, Kenneth menyuruh cuci tangan & bantu gandum)
    static let preMinigameDialogue: [VillageQuestDialogueLine] = [
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "I’ve got a basket for you."
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "[Without looking up.] Leave it there. Are your hands clean?"
        ),
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "Clean enough."
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "Wash them first."
        ),
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "Alright, but I was going to see Roland first. I haven’t seen him in a while. He’s been too busy looking after the animals."
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "Roland isn’t going anywhere. Wash your hands and help me with these seeds first."
        ),
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "[Washes his hands in the water basin.]"
        )
    ]

    // 2. Dialog saat minigame berlangsung (Menyortir biji gandum di tampah)
    static let midMinigameDialogue: [VillageQuestDialogueLine] = [
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "This pile looks smaller than I thought."
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "We had to move some of it. That wall over there has been damp since the rain. And these black ones need to be separated. Leave them in, and they’ll ruin the good ones."
        ),
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "Is the harvest enough?"
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "It’s enough. My mother counted."
        )
    ]

    // 3. Dialog setelah minigame selesai (Percakapan tentang tanah di balik bukit dan petunjuk ke Roland)
    static let postMinigameDialogue: [VillageQuestDialogueLine] = [
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "I wonder if the soil beyond the hills is anything like ours."
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "Not this again."
        ),
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "I’m just wondering."
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "The soil here is fine."
        ),
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "That’s not what I meant. The people who first found this valley must have come from somewhere else."
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "[He looks sharply at Arthur.] And we have no idea how many of them never made it here. Listen, we have everything we need. If everyone takes care of what we have and follows the rules, we’ll be fine."
        ),
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "[Arthur falls silent for a moment.]"
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "You’re always counting what we might find out there, Arthur. Just once... try counting what we could lose."
        ),
        VillageQuestDialogueLine(
            speaker: "Kenneth",
            text: "[He returns his attention to the seeds.] There. We’re done. Roland’s at the animal pens. Go bother him."
        ),
        VillageQuestDialogueLine(
            speaker: "Arthur",
            text: "Gladly."
        )
    ]
}
