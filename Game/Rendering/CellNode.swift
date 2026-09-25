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

        addMicroBiomeDebugGrid(microBiomeGrid, gridID: gridID, piece: piece, cellSize: mapper.cellSize)

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

    private func addMicroBiomeDebugGrid(_ microBiomeGrid: MicroBiomeGrid, gridID: GridID, piece: WorldPiece, cellSize: CGFloat) {
        if let override = TileAssetResolver.override(for: piece, gridID: gridID) {
            addChild(TileAssetResolver.shadowNode(size: cellSize))
            let tile = TileAssetResolver.overrideNode(for: override, size: cellSize)
            tile.alpha = 0.92
            tile.zPosition = 0.5
            addChild(tile)
            return
        }

        let dimension = MicroBiomeGrid.dimension
        let subcellSize = cellSize / CGFloat(dimension)
        let half = cellSize / 2
        for position in MicroGridPosition.allPositions {
            let origin = CGPoint(
                x: -half + CGFloat(position.x) * subcellSize,
                y: half - CGFloat(position.y + 1) * subcellSize
            )
            let rect = CGRect(origin: origin, size: CGSize(width: subcellSize, height: subcellSize))
            if let split = microBiomeGrid.split(at: position) {
                addMicroBiomeSplit(split, rect: rect)
            } else if let biome = microBiomeGrid.biome(at: position) {
                let cell = SKShapeNode(rect: rect)
                cell.fillColor = biome.debugColor
                cell.strokeColor = .clear
                cell.zPosition = 0.5
                addChild(cell)
            }
        }

    }

    private func addMicroBiomeSplit(_ split: MicroBiomeSplit, rect: CGRect) {
        let background = SKShapeNode(rect: rect)
        background.fillColor = split.secondaryBiome.debugColor
        background.strokeColor = .clear
        background.zPosition = 0.5
        addChild(background)

        let overlay = SKShapeNode(path: splitPath(for: split.primaryCorner, rect: rect))
        overlay.fillColor = split.primaryBiome.debugColor
        overlay.strokeColor = .clear
        overlay.zPosition = 0.51
        addChild(overlay)
    }

    private func splitPath(for corner: MicroBiomeSplit.Corner, rect: CGRect) -> CGPath {
        let topLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let topRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.minY)
        let path = CGMutablePath()
        switch corner {
        case .topLeft:
            path.addLines(between: [topLeft, topRight, bottomLeft])
        case .topRight:
            path.addLines(between: [topRight, bottomRight, topLeft])
        case .bottomRight:
            path.addLines(between: [bottomRight, bottomLeft, topRight])
        case .bottomLeft:
            path.addLines(between: [bottomLeft, topLeft, bottomRight])
        }
        path.closeSubpath()
        return path
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
            return String(debugSymbol)
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
