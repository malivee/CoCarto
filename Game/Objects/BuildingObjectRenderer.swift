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
        let orientedAssetSize = quarterTurn
            ? CGSize(width: size.height, height: size.width)
            : size
        if isWorld, result == nil {
            // The footprint follows the tile, while artwork and its collision
            // stay upright at the transformed footprint's center.
            let collisionNode = SKNode()
            collisionNode.name = "BuildingCollision"
            collisionNode.physicsBody = makeCollisionBody(for: object.kind, size: orientedAssetSize)
            root.addChild(collisionNode)
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
            if isWorld {
                root.addChild(makeAssetShadow(size: orientedAssetSize, isWorld: true, kind: object.kind))
            }

            let texture = SKTexture(imageNamed: assetName)
            let sprite = SKSpriteNode(texture: texture)
            sprite.name = "BuildingAsset"
//            sprite.size = aspectFitSize(textureSize: texture.size(), in: assetSize)
            sprite.size = orientedAssetSize
            sprite.zRotation = 0
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

        let icon = SKLabelNode(fontNamed: GameFont.name)
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
        let title = SKLabelNode(fontNamed: GameFont.name)
        title.text = definition.title
        title.fontSize = min(isWorld ? 20 : 13, size.width / CGFloat(definition.title.count) * 1.9)
        title.verticalAlignmentMode = .center
        title.position.y = -size.height * 0.3
        root.addChild(title)
        root.zPosition = result == nil ? 0 : 50
        return root
    }

    private static func aspectFitSize(textureSize: CGSize, in bounds: CGSize) -> CGSize {
        guard textureSize.width > 0, textureSize.height > 0 else { return bounds }
        let scale = min(bounds.width / textureSize.width, bounds.height / textureSize.height)
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
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
            // Grandpa now stands on open ground in front of the house, so the
            // doorway no longer needs to be walkable. Keep the full house
            // solid to prevent the player from walking onto its walls/roof.
            body = rectangularCollision(
                width: 0.80,
                height: 0.84,
                yOffset: 0.06,
                size: size
            )
        case .well:
            // Keep the physical rim inside the one-subgrid interaction radius,
            // so the player can stand close enough to tap the well itself.
            body = SKPhysicsBody(circleOfRadius: min(size.width, size.height) * 0.22)
        case .buMaraHouse:
            // Mrs. Mara is now placed outside the artwork. Cover the main
            // house and roof while leaving the painted ground at the bottom
            // free for approaching and interacting with her.
            body = rectangularCollision(
                width: 0.78,
                height: 0.52,
                yOffset: 0.10,
                xOffset: 0.01,
                size: size
            )
        case .barn:
            body = barnCollision(size: size)
        case .animalPen:
            body = animalPenCollision(size: size)
        case .annethHouse:
            body = annethHouseCollision(size: size)
        case .rockSalt:
            body = doorwayCollision(width: 0.58, upperHeight: 0.42, entranceWidth: 0.40, size: size)
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
        xOffset: CGFloat = 0,
        size: CGSize
    ) -> SKPhysicsBody {
        SKPhysicsBody(
            rectangleOf: CGSize(width: size.width * width, height: size.height * height),
            center: CGPoint(x: size.width * xOffset, y: size.height * yOffset)
        )
    }

    private static func barnCollision(size: CGSize) -> SKPhysicsBody {
        // Kenneth is positioned outside the barn now, so the complete main
        // structure can be solid. Stop the body above the lowest post ends so
        // the open ground in front of him remains reachable.
        rectangularCollision(
            width: 0.86,
            height: 0.78,
            yOffset: 0.10,
            size: size
        )
    }

    private static func animalPenCollision(size: CGSize) -> SKPhysicsBody {
        // The pen is an open enclosure, not a solid building. Follow the fence
        // perimeter and leave a centered gate along the lower fence.
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size.width * 0.12, y: -size.height * 0.42))
        path.addLine(to: CGPoint(x: size.width * 0.28, y: -size.height * 0.22))
        path.addLine(to: CGPoint(x: size.width * 0.43, y: size.height * 0.08))
        path.addLine(to: CGPoint(x: size.width * 0.34, y: size.height * 0.20))
        path.addLine(to: CGPoint(x: -size.width * 0.18, y: size.height * 0.28))
        path.addLine(to: CGPoint(x: -size.width * 0.44, y: size.height * 0.08))
        path.addLine(to: CGPoint(x: -size.width * 0.36, y: -size.height * 0.12))
        path.addLine(to: CGPoint(x: -size.width * 0.12, y: -size.height * 0.42))
        return SKPhysicsBody(edgeChainFrom: path)
    }

    private static func annethHouseCollision(size: CGSize) -> SKPhysicsBody {
        // Match the sloping roof instead of using a wide rectangle whose empty
        // corners block the player. The smaller lower body covers the walls.
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: 0, y: size.height * 0.42))
        roofPath.addLine(to: CGPoint(x: size.width * 0.34, y: size.height * 0.04))
        roofPath.addLine(to: CGPoint(x: size.width * 0.08, y: -size.height * 0.10))
        roofPath.addLine(to: CGPoint(x: -size.width * 0.34, y: size.height * 0.02))
        roofPath.closeSubpath()

        let roof = SKPhysicsBody(polygonFrom: roofPath)
        let structure = rectangularCollision(
            width: 0.44,
            height: 0.18,
            yOffset: -0.14,
            size: size
        )
        return SKPhysicsBody(bodies: [roof, structure])
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
