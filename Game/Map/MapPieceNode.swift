import SpriteKit

final class MapPieceNode: SKNode {
    let pieceID: UUID

    init(
        piece: WorldPiece,
        mapper: MapGridMapper,
        interactionState: MapPieceInteractionState,
        mismatchedEdgesByLocalCell: [(GridPosition, [Direction])] = []
    ) {
        self.pieceID = piece.id
        super.init()
        name = MapNodeName.piece.rawValue
        zPosition = 20
        userData = [MapUserDataKey.pieceID.rawValue: piece.id.uuidString]
        position = mapper.mapPosition(for: piece.gridPosition)
        zRotation = piece.rotation.radians
        rebuildCells(
            piece: piece,
            mapper: mapper,
            interactionState: interactionState,
            mismatchedEdgesByLocalCell: mismatchedEdgesByLocalCell
        )
    }

    func rebuildCells(
        piece: WorldPiece,
        mapper: MapGridMapper,
        interactionState: MapPieceInteractionState,
        mismatchedEdgesByLocalCell: [(GridPosition, [Direction])] = []
    ) {
        removeAllChildren()
        for cell in piece.cellDefinitions {
            addChild(MapCellNode(
                gridID: cell.id,
                localCell: cell.localPosition,
                edges: cell.edges,
                biomeEdges: cell.biomeEdges,
                microBiomeGrid: cell.microBiomeGrid,
                piece: piece,
                mapper: mapper,
                interactionState: interactionState,
                mismatchedEdges: mismatchedEdgesByLocalCell.first { $0.0 == cell.localPosition }?.1 ?? []
            ))
        }

        if interactionState == .fixed || interactionState == .lockedByPlayer {
            addIndicator(interactionState: interactionState, mapper: mapper)
        }
    }

    func applyPreview(
        piece: WorldPiece,
        preview: PiecePlacementPreview,
        mapper: MapGridMapper,
        animated: Bool = false,
        clockwise: Bool? = nil,
        mismatchedEdgesByLocalCell: [(GridPosition, [Direction])] = []
    ) {
        var previewPiece = piece
        previewPiece.gridPosition = preview.proposedPosition
        previewPiece.rotation = preview.proposedRotation
        position = preview.visualPosition

        if animated {
            let startingAngle = zRotation
            rebuildCells(
                piece: previewPiece,
                mapper: mapper,
                interactionState: .selected(isValid: preview.isValid),
                mismatchedEdgesByLocalCell: mismatchedEdgesByLocalCell
            )
            removeAction(forKey: "rotateFeedback")
            zRotation = startingAngle
            let quarterTurn: CGFloat = clockwise == true ? -.pi / 2 : .pi / 2
            let rotate = SKAction.rotate(byAngle: quarterTurn, duration: 0.11)
            rotate.timingMode = .easeInEaseOut
            let pulse = SKAction.sequence([
                .scale(to: 1.04, duration: 0.05),
                .scale(to: 1, duration: 0.06)
            ])
            pulse.timingMode = .easeInEaseOut
            run(.group([rotate, pulse]), withKey: "rotateFeedback")
        } else {
            rebuildCells(
                piece: previewPiece,
                mapper: mapper,
                interactionState: .selected(isValid: preview.isValid),
                mismatchedEdgesByLocalCell: mismatchedEdgesByLocalCell
            )
            zRotation = preview.proposedRotation.radians
        }
    }

    private func addIndicator(interactionState: MapPieceInteractionState, mapper: MapGridMapper) {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        switch interactionState {
        case .fixed:
            label.text = "LOCK"
        case .lockedByPlayer:
            label.text = "PLAYER"
        case .movable, .playerConnected, .selected:
            return
        }
        label.fontSize = 13
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: mapper.cellSize * 0.58)
        label.zPosition = 10
        addChild(label)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}

enum MapNodeName: String {
    case hud = "MapHUD"
    case contentRoot = "MapContentRoot"
    case background = "MapBackground"
    case piece = "MapPieceNode"
    case cell = "MapCellNode"
    case rotateLeftButton = "MapRotateLeftButton"
    case rotateRightButton = "MapRotateRightButton"
    case cancelButton = "MapCancelButton"
    case confirmButton = "MapConfirmButton"
    case exitButton = "MapExitButton"
    case inventoryToggle = "MapInventoryToggle"
    case inventoryPanel = "MapInventoryPanel"
    case inventoryItem = "MapInventoryItem"
    case enterButton = "EnterMapButton"
    case resetButton = "ResetPuzzleButton"
    case saveButton = "SaveGameButton"
    case loadButton = "LoadGameButton"
    case footprint3Button = "Footprint3Button"
    case footprint6Button = "Footprint6Button"
    case footprint69Button = "Footprint69Button"
    case footprint915Button = "Footprint915Button"
}

enum MapUserDataKey: String {
    case pieceID
}
