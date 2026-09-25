import CoreGraphics
import Foundation

struct PlayerSpatialState: Codable, Equatable, Sendable {
    var pieceID: UUID
    var localPositionInPiece: CGPoint
}
