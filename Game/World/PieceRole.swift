enum PieceRole: String, CaseIterable, Codable, Hashable, Sendable {
    case village
    case forestWest
    case forestEast
    case forestPass
    case hill
    case outerWilderness
    case z1
    case z2
    case l1
    case t1
    case s1

    var debugSymbol: Character {
        switch self {
        case .village:
            return "A"
        case .forestWest:
            return "B"
        case .forestEast:
            return "C"
        case .forestPass:
            return "D"
        case .hill:
            return "E"
        case .outerWilderness:
            return "F"
        case .z1:
            return "Z"
        case .z2:
            return "2"
        case .l1:
            return "L"
        case .t1:
            return "T"
        case .s1:
            return "S"
        }
    }
}
