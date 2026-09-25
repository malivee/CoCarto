import Foundation

struct MicroBiomeCell: Hashable, Codable, Sendable {
    let localPosition: MicroGridPosition
    let biome: BiomeType?
}
