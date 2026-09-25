import SpriteKit

final class MapCellNode: SKSpriteNode {
    init(
        gridID: GridID,
        localCell: GridPosition,
        edges: CellEdges,
        biomeEdges: CellBiomeEdges,
        microBiomeGrid: MicroBiomeGrid,
        piece: WorldPiece,
        mapper: MapGridMapper,
        interactionState: MapPieceInteractionState
    ) {
        let size = CGSize(width: mapper.cellSize, height: mapper.cellSize)
        super.init(texture: nil, color: piece.role.mapColor(for: interactionState), size: size)
        position = mapper.offset(for: localCell)
        alpha = interactionState.cellAlpha
        name = MapNodeName.cell.rawValue

        let border = SKShapeNode(rectOf: size)
        border.strokeColor = interactionState.borderColor
        border.lineWidth = interactionState.borderWidth
        border.fillColor = .clear
        border.zPosition = 1
        addChild(border)

        addMicroBiomeDebugGrid(microBiomeGrid, gridID: gridID, piece: piece, cellSize: mapper.cellSize)

        let symbol = SKLabelNode(fontNamed: "Menlo-Bold")
        symbol.text = "\(piece.role.debugName)-\(gridID.rawValue)"
        symbol.fontSize = mapper.cellSize * 0.16
        symbol.fontColor = .white
        symbol.verticalAlignmentMode = .center
        symbol.horizontalAlignmentMode = .center
        symbol.zPosition = 2
        addChild(symbol)

        addEdgeDebugLabels(edges: edges, cellSize: mapper.cellSize)
        addBiomeEdgeDebugLabels(edges: biomeEdges, cellSize: mapper.cellSize)
    }

    private func addMicroBiomeDebugGrid(_ microBiomeGrid: MicroBiomeGrid, gridID: GridID, piece: WorldPiece, cellSize: CGFloat) {
//        if let override = TileAssetResolver.override(for: piece, gridID: gridID) {
//            let tile = TileAssetResolver.overrideNode(for: override, size: cellSize)
//            tile.alpha = 0.92
//            tile.zPosition = 0.5
//            addChild(tile)
//            addGridLines(dimension: MicroBiomeGrid.dimension, cellSize: cellSize)
//            return
//        }

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
        addGridLines(dimension: dimension, cellSize: cellSize)
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

    private func addGridLines(dimension: Int, cellSize: CGFloat) {
        let path = CGMutablePath()
        let half = cellSize / 2
        let step = cellSize / CGFloat(dimension)
        for index in 1..<dimension {
            let offset = -half + CGFloat(index) * step
            path.move(to: CGPoint(x: offset, y: -half))
            path.addLine(to: CGPoint(x: offset, y: half))
            path.move(to: CGPoint(x: -half, y: offset))
            path.addLine(to: CGPoint(x: half, y: offset))
        }
        let lines = SKShapeNode(path: path)
        lines.strokeColor = SKColor.gray.withAlphaComponent(0.5)
        lines.lineWidth = 1
        lines.zPosition = 0.6
        addChild(lines)
    }

    private func addEdgeDebugLabels(edges: CellEdges, cellSize: CGFloat) {
        for direction in Direction.allCases {
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = edges[direction].debugSymbol
            label.fontSize = 10
            label.fontColor = edges[direction].debugColor
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
            label.fontSize = 12
            label.fontColor = edges[direction].debugColor
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zPosition = 4
            label.position = biomeEdgeLabelPosition(direction: direction, cellSize: cellSize)
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

    private func biomeEdgeLabelPosition(direction: Direction, cellSize: CGFloat) -> CGPoint {
        let inset = cellSize * 0.47
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

enum MapPieceInteractionState: Equatable {
    case fixed
    case lockedByPlayer
    case movable
    case playerConnected
    case selected(isValid: Bool)

    var cellAlpha: CGFloat {
        switch self {
        case .fixed:
            return 0.46
        case .lockedByPlayer:
            return 0.62
        case .movable, .playerConnected:
            return 0.88
        case .selected(let isValid):
            return isValid ? 1.0 : 0.52
        }
    }

    var borderColor: SKColor {
        switch self {
        case .fixed:
            return .lightGray
        case .lockedByPlayer:
            return .cyan
        case .movable:
            return .black
        case .playerConnected:
            return .systemGreen
        case .selected(let isValid):
            return isValid ? .systemGreen : .systemRed
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .fixed, .lockedByPlayer, .playerConnected:
            return 4
        case .movable:
            return 2
        case .selected:
            return 6
        }
    }
}

private extension EdgeType {
    var debugColor: SKColor {
        switch self {
        case .open:
            return .white
        case .path:
            return .systemGreen
        case .blocked:
            return .systemRed
        case .forest:
            return .systemMint
        case .cliff:
            return .systemOrange
        }
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

    func mapColor(for state: MapPieceInteractionState) -> SKColor {
        let base: SKColor
        switch self {
        case .village:
            base = SKColor(red: 0.48, green: 0.58, blue: 0.66, alpha: 1)
        case .forestWest:
            base = SKColor(red: 0.28, green: 0.56, blue: 0.38, alpha: 1)
        case .forestEast:
            base = SKColor(red: 0.34, green: 0.64, blue: 0.48, alpha: 1)
        case .forestPass:
            base = SKColor(red: 0.60, green: 0.52, blue: 0.34, alpha: 1)
        case .hill:
            base = SKColor(red: 0.62, green: 0.48, blue: 0.72, alpha: 1)
        case .outerWilderness:
            base = SKColor(red: 0.38, green: 0.42, blue: 0.48, alpha: 1)
        case .z1:
            base = SKColor(red: 0.54, green: 0.42, blue: 0.36, alpha: 1)
        case .z2:
            base = SKColor(red: 0.46, green: 0.50, blue: 0.34, alpha: 1)
        case .l1:
            base = SKColor(red: 0.50, green: 0.44, blue: 0.58, alpha: 1)
        case .t1:
            base = SKColor(red: 0.34, green: 0.52, blue: 0.58, alpha: 1)
        case .s1:
            base = SKColor(red: 0.58, green: 0.48, blue: 0.30, alpha: 1)
        }

        switch state {
        case .fixed:
            return base.withAlphaComponent(0.65)
        case .lockedByPlayer:
            return base.withAlphaComponent(0.8)
        case .movable, .playerConnected, .selected:
            return base
        }
    }
}
