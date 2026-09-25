import Foundation

enum VillageQuest5Catalog {
    static let questNumber = 5
    static let title = "Quest 5 - Temui Anneth Dirumahnya"
    static let mapObjective = "Place Anneth home"
    static let worldObjective = "Meet Anneth at her home"

    static let dialogue: [VillageQuestDialogueLine] = [
        .init(speaker: "Arthur", text: "Anneth? Roland said you wanted to see me."),
        .init(speaker: "Anneth", text: "That pile hasn’t been washed."),
        .init(speaker: "Arthur", text: "The tubers?"),
        .init(speaker: "Anneth", text: "Yes. Wash them before you take yours."),
        .init(speaker: "Arthur", text: "I was going to."),
        .init(speaker: "Anneth", text: "Then do it over there. Don’t mix them with the ones I’ve already washed."),
        .init(speaker: "Narration", text: "Arthur carefully moves the pile of tubers to the other side of the table."),
        .init(speaker: "Arthur", text: "Roland said you saved some for me."),
        .init(speaker: "Anneth", text: "I did. But I’m not sending you home with spoiled ones, am I?"),
        .init(speaker: "Arthur", text: "Fair enough."),
        .init(speaker: "Anneth", text: "Good. Dirty ones here. Washed ones in the basket.")
    ]
}
