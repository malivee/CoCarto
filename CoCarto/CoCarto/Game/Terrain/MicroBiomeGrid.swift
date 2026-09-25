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

    func biome(at localPosition: MicroGridPosition) -> BiomeType {
        biomes[index(for: localPosition)]
    }

    mutating func setBiome(_ biome: BiomeType, at localPosition: MicroGridPosition) {
        biomes[index(for: localPosition)] = biome
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
            rotatedBiomes[index(for: targetPosition)] = biome(at: sourcePosition)
        }
        return try! MicroBiomeGrid(biomes: rotatedBiomes)
    }

    func debugRows() -> [String] {
        (0..<Self.dimension).map { y in
            (0..<Self.dimension)
                .map { x in String(biome(at: MicroGridPosition(x: x, y: y)).debugSymbol) }
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let biomes = try container.decode([BiomeType].self, forKey: .biomes)
        try self.init(biomes: biomes)
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
