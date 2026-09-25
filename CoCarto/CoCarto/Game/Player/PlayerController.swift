import CoreGraphics
import Foundation
import SpriteKit

final class PlayerController {
    private let mapper: WorldGridMapper
    private var worldState: WorldState
    private let movementSpeed: CGFloat

    private(set) var state = PlayerState(currentPieceID: nil, currentCell: nil, localPosition: .zero)

    init(mapper: WorldGridMapper, worldState: WorldState, movementSpeed: CGFloat = 360) {
        self.mapper = mapper
        self.worldState = worldState
        self.movementSpeed = movementSpeed
    }

    func updateWorldState(_ worldState: WorldState) {
        self.worldState = worldState
    }

    func spawnPlayerNode() -> PlayerNode {
        let playerNode = PlayerNode()
        playerNode.position = spawnPosition()
        updateState(from: playerNode.position)
        return playerNode
    }

    func update(playerNode: PlayerNode, movementVector: CGVector) {
        playerNode.physicsBody?.velocity = CGVector(
            dx: movementVector.dx * movementSpeed,
            dy: movementVector.dy * movementSpeed
        )
        updateState(from: playerNode.position)
    }

    func stop(playerNode: PlayerNode) {
        playerNode.physicsBody?.velocity = .zero
        updateState(from: playerNode.position)
    }

    func updateState(from worldPosition: CGPoint) {
        state = resolveState(at: worldPosition)
    }

    func resolveState(at worldPosition: CGPoint) -> PlayerState {
        let cell = mapper.gridPosition(containing: worldPosition)
        let center = mapper.worldPosition(for: cell)
        let pieceID = worldState.occupancy.pieceID(at: cell)
        let spatialState: PlayerSpatialState?

        if let pieceID, let piece = worldState.piece(id: pieceID) {
            let transform = PieceWorldTransform(piece: piece, mapper: mapper)
            spatialState = PlayerSpatialState(
                pieceID: pieceID,
                localPositionInPiece: transform.worldToLocal(worldPosition)
            )
        } else {
            spatialState = nil
        }

        return PlayerState(
            currentPieceID: pieceID,
            currentCell: pieceID == nil ? nil : cell,
            localPosition: CGPoint(x: worldPosition.x - center.x, y: worldPosition.y - center.y),
            spatialState: spatialState
        )
    }

    func worldPosition(for spatialState: PlayerSpatialState, in worldState: WorldState? = nil) -> CGPoint? {
        let state = worldState ?? self.worldState
        guard let piece = state.piece(id: spatialState.pieceID) else {
            return nil
        }

        return PieceWorldTransform(piece: piece, mapper: mapper).localToWorld(spatialState.localPositionInPiece)
    }

    func apply(spatialState: PlayerSpatialState, to playerNode: PlayerNode) -> Bool {
        guard let worldPosition = worldPosition(for: spatialState) else {
            return false
        }

        playerNode.position = worldPosition
        playerNode.physicsBody?.velocity = .zero
        updateState(from: worldPosition)
        return state.currentPieceID == spatialState.pieceID
    }

    private func spawnPosition() -> CGPoint {
        let spawnPiece = worldState.piece(role: .village) ?? worldState.piece(role: .z1) ?? worldState.pieces.first
        guard let spawnCell = spawnPiece?.occupiedCells().sortedForDeterministicDisplay.first else {
            return .zero
        }

        return mapper.worldPosition(for: spawnCell)
    }
}

private extension Set where Element == GridPosition {
    var sortedForDeterministicDisplay: [GridPosition] {
        sorted { lhs, rhs in
            if lhs.y == rhs.y {
                return lhs.x < rhs.x
            }
            return lhs.y < rhs.y
        }
    }
}
