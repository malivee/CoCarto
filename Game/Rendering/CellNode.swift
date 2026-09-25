import SpriteKit

final class CellNode: SKNode {
    let gridPosition: GridPosition
    let pieceID: UUID

    init(
        gridID: GridID,
        localCell: GridPosition,
        globalCell: GridPosition,
        biomeEdges: CellBiomeEdges,
        microBiomeGrid: MicroBiomeGrid,
        piece: WorldPiece,
        mapper: WorldGridMapper,
        showsDebugLabels: Bool
    ) {
        self.gridPosition = globalCell
        self.pieceID = piece.id
        super.init()

        position = CGPoint(
            x: CGFloat(localCell.x) * mapper.cellSize,
            y: CGFloat(localCell.y) * mapper.cellSize
        )

        let floor = SKSpriteNode(color: piece.role.grayboxColor, size: CGSize(width: mapper.cellSize, height: mapper.cellSize))
        floor.alpha = piece.isMovable ? 0.78 : 0.95
        floor.zPosition = 0
        addChild(floor)

        addMicroBiomeDebugGrid(microBiomeGrid, cellSize: mapper.cellSize)

        let border = SKShapeNode(rectOf: CGSize(width: mapper.cellSize, height: mapper.cellSize))
        border.strokeColor = piece.isMovable ? .darkGray : .white
        border.lineWidth = piece.isMovable ? 3 : 6
        border.fillColor = .clear
        border.zPosition = 1
        addChild(border)

        guard showsDebugLabels else {
            return
        }

        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "\(piece.role.debugName)-\(gridID.rawValue)  \(globalCell.x),\(globalCell.y)"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 2
        addChild(label)

        addBiomeEdgeDebugLabels(edges: biomeEdges, cellSize: mapper.cellSize)
    }

    private func addMicroBiomeDebugGrid(_ microBiomeGrid: MicroBiomeGrid, cellSize: CGFloat) {
        let microSize = cellSize / CGFloat(MicroBiomeGrid.dimension)
        let topLeft = CGPoint(x: -cellSize / 2 + microSize / 2, y: cellSize / 2 - microSize / 2)

        for microCell in microBiomeGrid.cells() {
            let node = SKSpriteNode(
                color: microCell.biome.debugColor,
                size: CGSize(width: microSize - 1, height: microSize - 1)
            )
            node.position = CGPoint(
                x: topLeft.x + CGFloat(microCell.localPosition.x) * microSize,
                y: topLeft.y - CGFloat(microCell.localPosition.y) * microSize
            )
            node.alpha = 0.92
            node.zPosition = 0.5
            addChild(node)
        }
    }

    private func addEdgeDebugLabels(edges: CellEdges, cellSize: CGFloat) {
        for direction in Direction.allCases {
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = edges[direction].debugSymbol
            label.fontSize = 18
            label.fontColor = .yellow
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zPosition = 3
            label.position = edgeLabelPosition(direction: direction, cellSize: cellSize)
            addChild(label)
        }
    }

    private func addBiomeEdgeDebugLabels(edges: CellBiomeEdges, cellSize: CGFloat) {
        for direction in Direction.allCases {
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = String(edges[direction].debugSymbol)
            label.fontSize = 18
            label.fontColor = edges[direction].debugColor
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zPosition = 3
            label.position = edgeLabelPosition(direction: direction, cellSize: cellSize)
            addChild(label)
        }
    }

    private func edgeLabelPosition(direction: Direction, cellSize: CGFloat) -> CGPoint {
        let inset = cellSize * 0.36
        switch direction {
        case .north:
            return CGPoint(x: 0, y: inset)
        case .east:
            return CGPoint(x: inset, y: 0)
        case .south:
            return CGPoint(x: 0, y: -inset)
        case .west:
            return CGPoint(x: -inset, y: 0)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}

private extension PieceRole {
    var debugName: String {
        switch self {
        case .z1, .z2, .l1, .t1, .s1:
            return rawValue.uppercased()
        case .village, .forestWest, .forestEast, .forestPass, .hill, .outerWilderness:
            return String(debugSymbol)
        }
    }

    var grayboxColor: SKColor {
        switch self {
        case .village:
            return SKColor(red: 0.45, green: 0.55, blue: 0.62, alpha: 1)
        case .forestWest:
            return SKColor(red: 0.27, green: 0.48, blue: 0.36, alpha: 1)
        case .forestEast:
            return SKColor(red: 0.31, green: 0.56, blue: 0.44, alpha: 1)
        case .forestPass:
            return SKColor(red: 0.50, green: 0.46, blue: 0.34, alpha: 1)
        case .hill:
            return SKColor(red: 0.55, green: 0.48, blue: 0.64, alpha: 1)
        case .outerWilderness:
            return SKColor(red: 0.35, green: 0.38, blue: 0.43, alpha: 1)
        case .z1:
            return SKColor(red: 0.54, green: 0.42, blue: 0.36, alpha: 1)
        case .z2:
            return SKColor(red: 0.46, green: 0.50, blue: 0.34, alpha: 1)
        case .l1:
            return SKColor(red: 0.50, green: 0.44, blue: 0.58, alpha: 1)
        case .t1:
            return SKColor(red: 0.34, green: 0.52, blue: 0.58, alpha: 1)
        case .s1:
            return SKColor(red: 0.58, green: 0.48, blue: 0.30, alpha: 1)
        }
    }
}
