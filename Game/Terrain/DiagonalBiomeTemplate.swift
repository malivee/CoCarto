import Foundation

enum DiagonalBiomeTemplate: String, Codable, CaseIterable, Sendable {
    case topLeftTriangle
    case topRightTriangle
    case bottomLeftTriangle
    case bottomRightTriangle
    case northwestSoutheastHalf
    case northeastSouthwestHalf

    func grid(primaryBiome: BiomeType, secondaryBiome: BiomeType) -> MicroBiomeGrid {
        let matrix = (0..<MicroBiomeGrid.dimension).map { y in
            (0..<MicroBiomeGrid.dimension).map { x in
                containsPrimaryBiome(x: x, y: y) ? primaryBiome : secondaryBiome
            }
        }
        return try! MicroBiomeGrid(matrix: matrix)
    }

    private func containsPrimaryBiome(x: Int, y: Int) -> Bool {
        let maxIndex = MicroBiomeGrid.dimension - 1
        switch self {
        case .topLeftTriangle:
            return x + y <= maxIndex
        case .topRightTriangle:
            return x >= y
        case .bottomLeftTriangle:
            return x <= y
        case .bottomRightTriangle:
            return x + y >= maxIndex
        case .northwestSoutheastHalf:
            return x <= y
        case .northeastSouthwestHalf:
            return x + y <= maxIndex
        }
    }
}
