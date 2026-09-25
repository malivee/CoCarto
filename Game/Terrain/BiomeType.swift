import Foundation

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
}
