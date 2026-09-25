import Foundation

enum MicroBiomeGridError: Error, Equatable, Sendable {
    case invalidCellCount(Int)
    case invalidRowCount(Int)
    case invalidColumnCount(row: Int, count: Int)
    case invalidPosition(x: Int, y: Int)
}

struct MicroBiomeGrid: Codable, Equatable, Hashable, Sendable {
    static let dimension = 6
    static let cellCount = dimension * dimension

    private var biomes: [BiomeType]
    private var splits: [MicroGridPosition: MicroBiomeSplit] = [:]

    init(biomes: [BiomeType]) throws {
        guard biomes.count == Self.cellCount else {
            throw MicroBiomeGridError.invalidCellCount(biomes.count)
        }
        self.biomes = biomes
    }

    init(matrix: [[BiomeType]]) throws {
        guard matrix.count == Self.dimension else {
            throw MicroBiomeGridError.invalidRowCount(matrix.count)
        }

        var biomes: [BiomeType] = []
        biomes.reserveCapacity(Self.cellCount)
        for (rowIndex, row) in matrix.enumerated() {
            guard row.count == Self.dimension else {
                throw MicroBiomeGridError.invalidColumnCount(row: rowIndex, count: row.count)
            }
            biomes.append(contentsOf: row)
        }

        try self.init(biomes: biomes)
    }

    static func uniform(_ biome: BiomeType) -> MicroBiomeGrid {
        try! MicroBiomeGrid(biomes: Array(repeating: biome, count: cellCount))
    }

    func biome(at localPosition: MicroGridPosition) -> BiomeType? {
        splits[localPosition] == nil ? biomes[index(for: localPosition)] : nil
    }

    mutating func setBiome(_ biome: BiomeType, at localPosition: MicroGridPosition) {
        splits[localPosition] = nil
        biomes[index(for: localPosition)] = biome
    }

    func split(at position: MicroGridPosition) -> MicroBiomeSplit? {
        splits[position]
    }

    mutating func setSplit(_ split: MicroBiomeSplit, at position: MicroGridPosition) {
        splits[position] = split
    }

    func cells() -> [MicroBiomeCell] {
        MicroGridPosition.allPositions.map { position in
            MicroBiomeCell(localPosition: position, biome: biome(at: position))
        }
    }

    func rotated(by rotation: GridRotation) -> MicroBiomeGrid {
        var rotatedBiomes = Array(repeating: BiomeType.rocksalt, count: Self.cellCount)
        for sourcePosition in MicroGridPosition.allPositions {
            let targetPosition = sourcePosition.rotated(by: rotation)
            rotatedBiomes[index(for: targetPosition)] = biomes[index(for: sourcePosition)]
        }
        var result = try! MicroBiomeGrid(biomes: rotatedBiomes)
        for (position, split) in splits {
            result.setSplit(split.rotated(by: rotation), at: position.rotated(by: rotation))
        }
        return result
    }

    func debugRows() -> [String] {
        (0..<Self.dimension).map { y in
            (0..<Self.dimension)
                .map { x in String(biome(at: MicroGridPosition(x: x, y: y))?.debugSymbol ?? "·") }
                .joined(separator: " ")
        }
    }

    func debugDescription() -> String {
        debugRows().joined(separator: "\n")
    }

    private func index(for localPosition: MicroGridPosition) -> Int {
        localPosition.y * Self.dimension + localPosition.x
    }

    private enum CodingKeys: String, CodingKey {
        case biomes
        case splits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let biomes = try container.decode([BiomeType].self, forKey: .biomes)
        try self.init(biomes: biomes)
        splits = try container.decodeIfPresent([MicroGridPosition: MicroBiomeSplit].self, forKey: .splits) ?? [:]
    }
}

extension MicroGridPosition {
    static var allPositions: [MicroGridPosition] {
        (0..<MicroBiomeGrid.dimension).flatMap { y in
            (0..<MicroBiomeGrid.dimension).map { x in
                MicroGridPosition(x: x, y: y)
            }
        }
    }

    func rotated(by rotation: GridRotation) -> MicroGridPosition {
        let maxIndex = MicroBiomeGrid.dimension - 1
        switch rotation {
        case .degrees0:
            return self
        case .degrees90:
            return MicroGridPosition(x: maxIndex - y, y: x)
        case .degrees180:
            return MicroGridPosition(x: maxIndex - x, y: maxIndex - y)
        case .degrees270:
            return MicroGridPosition(x: y, y: maxIndex - x)
        }
    }
}

// The corner identifies the right-angle corner of the primary colored half.
// Split cells have visual colors but deliberately have no logical biome.
struct MicroBiomeSplit: Codable, Hashable, Sendable {
    enum Corner: Int, Codable, Sendable {
        case topLeft, topRight, bottomRight, bottomLeft
    }

    let primaryBiome: BiomeType
    let secondaryBiome: BiomeType
    let primaryCorner: Corner

    func rotated(by rotation: GridRotation) -> MicroBiomeSplit {
        MicroBiomeSplit(
            primaryBiome: primaryBiome,
            secondaryBiome: secondaryBiome,
            primaryCorner: Corner(rawValue: (primaryCorner.rawValue + rotation.rawValue / 90) % 4)!
        )
    }
}

extension MicroBiomeGrid {
    static func diagonal(primaryBiome: BiomeType, secondaryBiome: BiomeType, primaryCorner: MicroBiomeSplit.Corner) -> MicroBiomeGrid {
        var grid = uniform(secondaryBiome)
        let last = dimension - 1
        for position in MicroGridPosition.allPositions {
            let distance: Int
            switch primaryCorner {
            case .topLeft: distance = position.x + position.y - last
            case .topRight: distance = position.y - position.x
            case .bottomRight: distance = last - position.x - position.y
            case .bottomLeft: distance = position.x - position.y
            }
            if distance < 0 || primaryBiome == secondaryBiome {
                grid.setBiome(primaryBiome, at: position)
            } else if distance == 0 {
                grid.setSplit(MicroBiomeSplit(primaryBiome: primaryBiome, secondaryBiome: secondaryBiome, primaryCorner: primaryCorner), at: position)
            }
        }
        return grid
    }
}
