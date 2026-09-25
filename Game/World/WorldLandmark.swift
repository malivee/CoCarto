import Foundation

struct WorldLandmark: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: LandmarkID
    let pieceRole: PieceRole
    let localCell: GridPosition
    var state: LandmarkState
}
