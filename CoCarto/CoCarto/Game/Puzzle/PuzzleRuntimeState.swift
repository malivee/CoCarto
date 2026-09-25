struct PuzzleRuntimeState: Codable, Equatable, Sendable {
    let id: PuzzleID
    var status: PuzzleStatus
}
