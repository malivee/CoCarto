enum PuzzleID: String, Codable, Hashable, Sendable {
    case snowRoutePrototype
}

enum PuzzleStatus: String, Codable, Hashable, Sendable {
    case inactive
    case active
    case completed
}
