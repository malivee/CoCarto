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

        addMicroBiomeDebugGrid(microBiomeGrid, cellSize: mapper.cellSize)

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

    private func addMicroBiomeDebugGrid(_ microBiomeGrid: MicroBiomeGrid, cellSize: CGFloat) {
        let microSize = cellSize / CGFloat(MicroBiomeGrid.dimension)
        let topLeft = CGPoint(x: -cellSize / 2 + microSize / 2, y: cellSize / 2 - microSize / 2)

        for microCell in microBiomeGrid.cells() {
            let node = MicroBiomeDebugNode.make(
                biome: microCell.biome,
                split: microBiomeGrid.split(at: microCell.localPosition),
                size: microSize - 1
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

extension BiomeType {
    var debugColor: SKColor {
        switch self {
        case .villageSoil, .hillSoil:
            return SKColor(red: 0.96, green: 0.76, blue: 0.20, alpha: 1)
        case .naturalGrass:
            return SKColor(red: 0.20, green: 0.76, blue: 0.38, alpha: 1)
        case .rocksalt:
            return SKColor(red: 0.18, green: 0.52, blue: 0.95, alpha: 1)
        case .darkGreenForest:
            return SKColor(red: 0.10, green: 0.43, blue: 0.25, alpha: 1)
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
