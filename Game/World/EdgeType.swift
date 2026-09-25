enum EdgeType: String, Codable, Hashable, Sendable {
    case open
    case path
    case blocked
    case forest
    case cliff

    var debugSymbol: String {
        switch self {
        case .open:
            return "O"
        case .path:
            return "P"
        case .blocked:
            return "B"
        case .forest:
            return "F"
        case .cliff:
            return "C"
        }
    }
}
