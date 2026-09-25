import Foundation

enum DiagonalBiomeTemplate: String, Codable, CaseIterable, Sendable {
    case topLeftTriangle
    case topRightTriangle
    case bottomLeftTriangle
    case bottomRightTriangle
    case northwestSoutheastHalf
    case northeastSouthwestHalf

    func grid(primaryBiome: BiomeType, secondaryBiome: BiomeType) -> MicroBiomeGrid {
        let corner: MicroBiomeSplit.Corner
        switch self {
        case .topLeftTriangle, .northeastSouthwestHalf: corner = .topLeft
        case .topRightTriangle: corner = .topRight
        case .bottomLeftTriangle, .northwestSoutheastHalf: corner = .bottomLeft
        case .bottomRightTriangle: corner = .bottomRight
        }
        return .diagonal(primaryBiome: primaryBiome, secondaryBiome: secondaryBiome, primaryCorner: corner)
    }
}
