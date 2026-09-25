struct EdgeCompatibility: Sendable {
    static func canConnect(_ lhs: EdgeType, _ rhs: EdgeType) -> Bool {
        switch (lhs, rhs) {
        case (.open, .open),
             (.open, .path),
             (.path, .open),
             (.path, .path):
            return true
        case (.blocked, _), (_, .blocked),
             (.forest, _), (_, .forest),
             (.cliff, _), (_, .cliff):
            return false
        }
    }
}
