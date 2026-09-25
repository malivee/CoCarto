import Foundation

struct ResolvedMicroBiomeCell: Hashable, Sendable {
    let globalPosition: GlobalMicroPosition
    let biome: BiomeType
    let pieceID: UUID
    let gridID: GridID
    let largeCellPosition: GridPosition
    let localMicroPosition: MicroGridPosition
    let resolvedMicroPosition: MicroGridPosition
}
