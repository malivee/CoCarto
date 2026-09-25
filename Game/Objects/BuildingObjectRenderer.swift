import SpriteKit

enum BuildingObjectRenderer {
    static let rootName = "buildingObjects"

    static func render(_ objects: [BuildingObject], in parent: SKNode, cellSize: CGFloat, isWorld: Bool) {
        parent.childNode(withName: rootName)?.removeFromParent()
        let root = SKNode()
        root.name = rootName
        root.zPosition = 40
        for object in objects {
            root.addChild(makeNode(object, cellSize: cellSize, isWorld: isWorld))
        }
        parent.addChild(root)
    }

    static func makeNode(_ object: BuildingObject, cellSize: CGFloat, isWorld: Bool, result: BuildingPlacementResult? = nil) -> SKNode {
        let definition = BuildingObjectCatalog.definition(for: object.kind)
        let dimensions = object.mapDimensions
        let microSize = cellSize / CGFloat(MicroBiomeGrid.dimension)
        let quarterTurn = object.rotation == .degrees90 || object.rotation == .degrees270
        let worldSize = definition.worldSize
        let size: CGSize
        if isWorld {
            let worldUnit = cellSize / CGFloat(WorldVisualSubcell.dimension)
            size = CGSize(width: CGFloat(quarterTurn ? worldSize.height : worldSize.width) * worldUnit,
                          height: CGFloat(quarterTurn ? worldSize.width : worldSize.height) * worldUnit)
        } else {
            size = CGSize(width: CGFloat(dimensions.width) * microSize, height: CGFloat(dimensions.height) * microSize)
        }
        let root = SKNode()
        root.position = CGPoint(
            x: (CGFloat(object.origin.x) + CGFloat(dimensions.width) / 2) * microSize - cellSize / 2,
            y: (CGFloat(object.origin.y) + CGFloat(dimensions.height) / 2) * microSize - cellSize / 2
        )
        let outline = SKShapeNode(rectOf: size, cornerRadius: 3)
        outline.fillColor = result == nil ? SKColor(red: 0.48, green: 0.29, blue: 0.16, alpha: 0.88) : .clear
        outline.strokeColor = result.map { $0 == .valid ? .systemGreen : .systemRed } ?? .white
        outline.lineWidth = result == nil ? 1.5 : 3
        root.addChild(outline)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        switch object.kind {
        case .well: icon.text = "◉"
        case .rockSalt: icon.text = "◆"
        case .animalPen: icon.text = "▥"
        default: icon.text = "⌂"
        }
        icon.fontSize = min(size.width, size.height) * 0.45
        icon.verticalAlignmentMode = .center
        icon.position.y = size.height * 0.08
        root.addChild(icon)
        let title = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        title.text = definition.title
        title.fontSize = min(isWorld ? 17 : 10, size.width / CGFloat(definition.title.count) * 1.5)
        title.verticalAlignmentMode = .center
        title.position.y = -size.height * 0.3
        root.addChild(title)
        root.zPosition = result == nil ? 0 : 50
        return root
    }
}
