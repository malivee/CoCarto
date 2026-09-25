import Foundation

// MARK: - Quest 4 Story Content

enum VillageQuest4Catalog {
    static let questNumber = 4
    static let title = "Quest 4 - Temui Roland di Kandang"
    static let mapObjective = "Place animal pen"
    static let worldObjective = "Meet Roland at animal pen"

    static let dialogue: [VillageQuestDialogueLine] = [
        .init(speaker: "Roland", text: "Find it yet?"),
        .init(speaker: "Arthur", text: "Find what?"),
        .init(speaker: "Roland", text: "Whatever it is you lost. You always walk around looking like you’re searching for a spoon at the bottom of a well."),
        .init(speaker: "Narration", text: "Roland smirks as he brushes the dust from his hands. Arthur only lets out a quiet huff and leans against the stack of wood beside him."),
        .init(speaker: "Arthur", text: "Someday... I want to see the forest boundary up close."),
        .init(speaker: "Narration", text: "Roland’s hands stop moving. His teasing smile fades almost immediately."),
        .init(speaker: "Roland", text: "Tell me first."),
        .init(speaker: "Arthur", text: "So you can report me?"),
        .init(speaker: "Roland", text: "So I know which idiot I have to go looking for."),
        .init(speaker: "Narration", text: "Roland looks directly at him now, completely serious."),
        .init(speaker: "Arthur", text: "I didn’t say I was going."),
        .init(speaker: "Roland", text: "Good. Glad you still know the difference between ‘want to’ and ‘going to.’"),
        .init(speaker: "Narration", text: "Roland picks up Arthur’s basket and hands it back to him."),
        .init(speaker: "Roland", text: "Yesterday, you climbed the warehouse beam just to check a nest. You only asked if the beam was strong enough after you were already up there."),
        .init(speaker: "Arthur", text: "The nest was empty."),
        .init(speaker: "Roland", text: "The beam almost snapped, Arthur."),
        .init(speaker: "Narration", text: "Arthur goes quiet. It was something he had deliberately kept from Grandpa."),
        .init(speaker: "Narration", text: "Roland lets out a slow sigh."),
        .init(speaker: "Roland", text: "Just... tell me, Arthur."),
        .init(speaker: "Arthur", text: "I will..."),
        .init(speaker: "Narration", text: "Roland watches him for another moment, then shakes his head and returns to his work."),
        .init(speaker: "Roland", text: "Oh, and before you disappear somewhere else... I ran into Anneth earlier."),
        .init(speaker: "Arthur", text: "What about her?"),
        .init(speaker: "Roland", text: "She said she saved some tubers from the harvest for you. Told me to send you over if I saw you."),
        .init(speaker: "Arthur", text: "She did?"),
        .init(speaker: "Roland", text: "Yeah. Go see her at her house before she starts wondering whether I forgot to tell you."),
        .init(speaker: "Arthur", text: "Alright. I’ll stop by."),
        .init(speaker: "Roland", text: "Good. And try not to climb anything on the way there.")
    ]
}
