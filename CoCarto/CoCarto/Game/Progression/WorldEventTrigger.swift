enum WorldEventTrigger: Equatable, Sendable {
    case puzzleCompleted(PuzzleID)

    func matches(_ event: GameDomainEvent) -> Bool {
        switch (self, event) {
        case (.puzzleCompleted(let expectedID), .puzzleCompleted(let actualID)):
            return expectedID == actualID
        default:
            return false
        }
    }
}
