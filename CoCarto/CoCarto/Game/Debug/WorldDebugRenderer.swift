import SpriteKit

final class WorldDebugRenderer {
    private let statusLabel: SKLabelNode

    init(debugRoot: SKNode) {
        statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        statusLabel.fontSize = 18
        statusLabel.fontColor = .white
        statusLabel.horizontalAlignmentMode = .left
        statusLabel.verticalAlignmentMode = .top
        statusLabel.numberOfLines = 0
        statusLabel.zPosition = 1_000
        debugRoot.addChild(statusLabel)
    }

    func update(
        playerState: PlayerState,
        worldState: WorldState,
        cameraPosition: CGPoint,
        sceneSize: CGSize,
        progressionText: String
    ) {
        statusLabel.position = CGPoint(
            x: cameraPosition.x - sceneSize.width * 0.46,
            y: cameraPosition.y + sceneSize.height * 0.42
        )

        let cellText: String
        if let currentCell = playerState.currentCell {
            cellText = "cell: \(currentCell.x),\(currentCell.y)"
        } else {
            cellText = "cell: void"
        }

        let pieceText: String
        if let pieceID = playerState.currentPieceID,
           let piece = worldState.piece(id: pieceID) {
            let movement = piece.isMovable ? "movable" : "fixed"
            pieceText = "piece: \(piece.role.debugSymbol) \(piece.role) (\(movement))"
        } else {
            pieceText = "piece: none"
        }

        let spatialText: String
        if let spatialState = playerState.spatialState,
           let piece = worldState.piece(id: spatialState.pieceID) {
            spatialText = "piece local: \(Int(spatialState.localPositionInPiece.x)),\(Int(spatialState.localPositionInPiece.y))\norigin: \(piece.gridPosition.x),\(piece.gridPosition.y) rot: \(piece.rotation.rawValue)"
        } else {
            spatialText = "piece local: none"
        }

        let connectivityText: String
        if let currentCell = playerState.currentCell {
            connectivityText = ConnectivityResolver().debugConnectivityDescription(for: currentCell, in: worldState)
        } else {
            connectivityText = "connectivity: none"
        }

        statusLabel.text = [
            "very disco graybox",
            cellText,
            pieceText,
            "cell local: \(Int(playerState.localPosition.x)),\(Int(playerState.localPosition.y))",
            spatialText,
            progressionText,
            connectivityText
        ].joined(separator: "\n")
    }
}
