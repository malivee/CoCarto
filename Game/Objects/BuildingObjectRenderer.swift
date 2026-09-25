import SpriteKit

enum BuildingObjectRenderer {
    static let rootName = "buildingObjects"
    static let nodeName = "BuildingObjectNode"
    static let objectIDKey = "buildingObjectID"
    static let quest6PickupName = "Quest6RockSaltPickup"

    static func render(_ objects: [BuildingObject], in parent: SKNode, cellSize: CGFloat, isWorld: Bool) {
        parent.childNode(withName: rootName)?.removeFromParent()
        let root = SKNode()
        root.name = rootName
        root.zPosition = 40
        var lastRockSaltNode: SKNode?
        for object in objects {
            let node = makeNode(object, cellSize: cellSize, isWorld: isWorld)
            root.addChild(node)
            if object.kind == .rockSalt { lastRockSaltNode = node }
        }
        if isWorld,
           objects.contains(where: { $0.kind == .annethHouse }),
           objects.filter({ $0.kind == .rockSalt }).count >= 3,
           VillageQuest5Progress.load().completed,
           !VillageQuest6Progress.load().pickedUpRockSalt,
           let lastRockSaltNode {
            lastRockSaltNode.addChild(makeQuest6Pickup())
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
        root.name = nodeName
        root.userData = [objectIDKey: object.id.uuidString]
        root.position = CGPoint(
            x: (CGFloat(object.origin.x) + CGFloat(dimensions.width) / 2) * microSize - cellSize / 2,
            y: (CGFloat(object.origin.y) + CGFloat(dimensions.height) / 2) * microSize - cellSize / 2
        )
        let outline = SKShapeNode(rectOf: size, cornerRadius: 3)
        let assetName = assetName(for: object.kind)
        let usesAsset = assetName != nil
        outline.fillColor = result == nil && !usesAsset
            ? SKColor(red: 0.48, green: 0.29, blue: 0.16, alpha: 0.88)
            : .clear
        outline.strokeColor = result.map { $0 == .valid ? .systemGreen : .systemRed }
            ?? (usesAsset ? .clear : .white)
        outline.lineWidth = result == nil ? 1.5 : 3
        outline.zPosition = 2
        root.addChild(outline)

        if let assetName {
            let assetSize = quarterTurn
                ? CGSize(width: size.height, height: size.width)
                : size
            if isWorld {
                root.addChild(makeAssetShadow(size: size, isWorld: true, kind: object.kind))
            }

            let sprite = SKSpriteNode(imageNamed: assetName)
            sprite.name = "BuildingAsset"
            sprite.size = assetSize
            sprite.zRotation = object.rotation.radians
            sprite.zPosition = 1
            root.addChild(sprite)
            root.zPosition = result == nil ? 0 : 50
            return root
        }

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

    private static func makeQuest6Pickup() -> SKNode {
        let root = SKNode()
        root.name = quest6PickupName
        root.position = CGPoint(x: 0, y: 54)
        root.zPosition = 20

        let crystal = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 24))
            path.addLine(to: CGPoint(x: 18, y: 3))
            path.addLine(to: CGPoint(x: 10, y: -20))
            path.addLine(to: CGPoint(x: -14, y: -17))
            path.addLine(to: CGPoint(x: -19, y: 4))
            path.closeSubpath()
            return path
        }())
        crystal.name = quest6PickupName
        crystal.fillColor = SKColor(red: 0.91, green: 0.96, blue: 0.92, alpha: 1)
        crystal.strokeColor = .white
        crystal.lineWidth = 3
        root.addChild(crystal)

        let pulse = SKAction.sequence([
            .scale(to: 1.12, duration: 0.55),
            .scale(to: 1.0, duration: 0.55)
        ])
        root.run(.repeatForever(pulse))
        return root
    }

    private static func assetName(for kind: BuildingObjectKind) -> String? {
        switch kind {
        case .arthurHouse:
            return "rumahArthur"
        case .well:
            return "sumur"
        case .buMaraHouse:
            return "rumahBuMara"
        case .annethHouse:
            return "rumahAnneth"
        case .barn, .animalPen, .rockSalt:
            return nil
        }
    }

    private static func makeAssetShadow(size: CGSize, isWorld: Bool, kind: BuildingObjectKind) -> SKShapeNode {
        let widthMultiplier: CGFloat = kind == .well ? 1.08 : 1.24
        let heightMultiplier: CGFloat = kind == .well
            ? (isWorld ? 0.36 : 0.42)
            : (isWorld ? 0.46 : 0.52)
        let shadowWidth = size.width * widthMultiplier
        let shadowHeight = size.height * heightMultiplier
        let shadowRect = CGRect(
            x: -shadowWidth / 2,
            y: -size.height / 2 - shadowHeight * 0.08,
            width: shadowWidth,
            height: shadowHeight
        )
        let shadow = SKShapeNode(ellipseIn: shadowRect)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.34)
        shadow.strokeColor = .clear
        shadow.zPosition = 0.25
        return shadow
    }
}
