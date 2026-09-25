struct CellEdges: Codable, Hashable, Sendable {
    var north: EdgeType
    var east: EdgeType
    var south: EdgeType
    var west: EdgeType

    static let open = CellEdges(north: .open, east: .open, south: .open, west: .open)
    static let path = CellEdges(north: .path, east: .path, south: .path, west: .path)
    static let blocked = CellEdges(north: .blocked, east: .blocked, south: .blocked, west: .blocked)

    subscript(direction: Direction) -> EdgeType {
        get {
            switch direction {
            case .north:
                return north
            case .east:
                return east
            case .south:
                return south
            case .west:
                return west
            }
        }
        set {
            switch direction {
            case .north:
                north = newValue
            case .east:
                east = newValue
            case .south:
                south = newValue
            case .west:
                west = newValue
            }
        }
    }

    func rotated(by rotation: GridRotation) -> CellEdges {
        var rotated = self
        for direction in Direction.allCases {
            rotated[direction.rotated(by: rotation)] = self[direction]
        }
        return rotated
    }
}

extension Direction {
    var opposite: Direction {
        switch self {
        case .north:
            return .south
        case .east:
            return .west
        case .south:
            return .north
        case .west:
            return .east
        }
    }

    func rotated(by rotation: GridRotation) -> Direction {
        switch rotation {
        case .degrees0:
            return self
        case .degrees90:
            switch self {
            case .north: return .west
            case .east: return .north
            case .south: return .east
            case .west: return .south
            }
        case .degrees180:
            return opposite
        case .degrees270:
            switch self {
            case .north: return .east
            case .east: return .south
            case .south: return .west
            case .west: return .north
            }
        }
    }
}
