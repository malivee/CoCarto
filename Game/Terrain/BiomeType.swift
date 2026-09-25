import Foundation
import SpriteKit

enum BiomeType: String, Codable, Hashable, CaseIterable, Sendable {
    case rocksalt
    case villageSoil
    case naturalGrass
    case darkGreenForest
    case hillSoil

    var debugSymbol: Character {
        switch self {
        case .rocksalt:
            return "R"
        case .villageSoil:
            return "V"
        case .naturalGrass:
            return "G"
        case .darkGreenForest:
            return "F"
        case .hillSoil:
            return "H"
        }
    }

    var debugColor: SKColor {
        switch self {
        case .villageSoil, .hillSoil:
            return SKColor(red: 0.96, green: 0.76, blue: 0.20, alpha: 1)
        case .naturalGrass:
            return SKColor(red: 0.20, green: 0.76, blue: 0.38, alpha: 1)
        case .rocksalt:
            return SKColor(red: 0.18, green: 0.52, blue: 0.95, alpha: 1)
        case .darkGreenForest:
            return SKColor(red: 0.10, green: 0.43, blue: 0.25, alpha: 1)
        }
    }
}
