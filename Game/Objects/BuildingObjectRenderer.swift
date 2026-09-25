import SpriteKit

enum BuildingObjectRenderer {
    static let rootName = "buildingObjects"
    static let nodeName = "BuildingObjectNode"
    static let objectIDKey = "buildingObjectID"

    static func render(_ objects: [BuildingObject], in parent: SKNode, cellSize: CGFloat, isWorld: Bool) {
        parent.childNode(withName: rootName)?.removeFromParent()
        let root = SKNode()
        root.name = rootName
        root.zPosition = 40
        for object in objects {
            let node = makeNode(object, cellSize: cellSize, isWorld: isWorld)
            root.addChild(node)
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
            let worldVisualScale: CGFloat = 1.35
            size = CGSize(
                width: CGFloat(quarterTurn ? worldSize.height : worldSize.width) * worldUnit * worldVisualScale,
                height: CGFloat(quarterTurn ? worldSize.width : worldSize.height) * worldUnit * worldVisualScale
            )
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
        if isWorld, result == nil {
            root.physicsBody = makeCollisionBody(for: object.kind, size: size)
        }
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
            if isWorld,
               object.kind == .rockSalt,
               VillageQuest6Progress.load().collectedMineIDs.contains(object.id) {
                sprite.alpha = 0.55
            }
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

    static func assetName(for kind: BuildingObjectKind) -> String? {
        switch kind {
        case .arthurHouse:
            return "rumahArthur"
        case .well:
            return "sumur"
        case .buMaraHouse:
            return "rumahBuMara"
        case .annethHouse:
            return "rumahAnneth"
        case .animalPen:
            return "kandang"
        case .rockSalt:
            return "rocksalt"
        case .barn:
            return "lumbung"
        }
    }

    private static func makeCollisionBody(for kind: BuildingObjectKind, size: CGSize) -> SKPhysicsBody {
        let body: SKPhysicsBody

        switch kind {
        case .arthurHouse:
            body = doorwayCollision(width: 0.90, upperHeight: 0.68, entranceWidth: 0.30, size: size)
        case .well:
            // Keep the physical rim inside the one-subgrid interaction radius,
            // so the player can stand close enough to tap the well itself.
            body = SKPhysicsBody(circleOfRadius: min(size.width, size.height) * 0.28)
        case .buMaraHouse:
            body = doorwayCollision(width: 0.92, upperHeight: 0.68, entranceWidth: 0.28, size: size)
        case .barn:
            body = doorwayCollision(width: 0.88, upperHeight: 0.70, entranceWidth: 0.32, size: size)
        case .animalPen:
            // The pen is much taller than the other assets. Keep its collision
            // on the rear half and leave a wider front opening for Roland.
            body = doorwayCollision(width: 0.86, upperHeight: 0.48, entranceWidth: 0.52, size: size)
        case .annethHouse:
            body = doorwayCollision(width: 0.90, upperHeight: 0.68, entranceWidth: 0.30, size: size)
        case .rockSalt:
            body = rectangularCollision(width: 0.82, height: 0.86, yOffset: 0, size: size)
        }

        body.isDynamic = false
        body.affectedByGravity = false
        body.friction = 0
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.building
        body.collisionBitMask = PhysicsCategory.player
        body.contactTestBitMask = 0
        return body
    }

    private static func rectangularCollision(
        width: CGFloat,
        height: CGFloat,
        yOffset: CGFloat,
        size: CGSize
    ) -> SKPhysicsBody {
        SKPhysicsBody(
            rectangleOf: CGSize(width: size.width * width, height: size.height * height),
            center: CGPoint(x: 0, y: size.height * yOffset)
        )
    }

    private static func doorwayCollision(
        width: CGFloat,
        upperHeight: CGFloat,
        entranceWidth: CGFloat,
        size: CGSize
    ) -> SKPhysicsBody {
        let lowerHeight = 1 - upperHeight
        let sideWidth = (width - entranceWidth) / 2
        let sideCenterX = (entranceWidth + sideWidth) / 2

        let upper = rectangularCollision(
            width: width,
            height: upperHeight,
            yOffset: (1 - upperHeight) / 2,
            size: size
        )
        let lowerLeft = SKPhysicsBody(
            rectangleOf: CGSize(width: size.width * sideWidth, height: size.height * lowerHeight),
            center: CGPoint(
                x: -size.width * sideCenterX,
                y: -size.height * upperHeight / 2
            )
        )
        let lowerRight = SKPhysicsBody(
            rectangleOf: CGSize(width: size.width * sideWidth, height: size.height * lowerHeight),
            center: CGPoint(
                x: size.width * sideCenterX,
                y: -size.height * upperHeight / 2
            )
        )
        return SKPhysicsBody(bodies: [upper, lowerLeft, lowerRight])
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
