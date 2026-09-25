enum WorldEventStatus: String, Codable, Hashable, Sendable {
    case inactive
    case completed
}

struct WorldEventState: Codable, Equatable, Hashable, Sendable {
    let id: WorldEventID
    var status: WorldEventStatus
}
