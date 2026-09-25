import Foundation

struct CellBiomeEdges: Codable, Equatable, Hashable, Sendable {
    let north: BiomeType
    let east: BiomeType
    let south: BiomeType
    let west: BiomeType

    static func uniform(_ biome: BiomeType) -> CellBiomeEdges {
        CellBiomeEdges(north: biome, east: biome, south: biome, west: biome)
    }

    subscript(direction: Direction) -> BiomeType {
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

    func debugDescription() -> String {
        "N=\(north.debugSymbol) E=\(east.debugSymbol) S=\(south.debugSymbol) W=\(west.debugSymbol)"
    }

    func rotated(by rotation: GridRotation) -> CellBiomeEdges {
        switch rotation {
        case .degrees0:
            return self
        case .degrees90:
            return CellBiomeEdges(north: east, east: south, south: west, west: north)
        case .degrees180:
            return CellBiomeEdges(north: south, east: west, south: north, west: east)
        case .degrees270:
            return CellBiomeEdges(north: west, east: north, south: east, west: south)
        }
    }
}
