import SpriteKit

/// World-only scenery above the ground tiles and below buildings/characters.
/// Decorative nodes have no physics bodies or quest interaction identifiers.
enum WorldDecorationRenderer {
    static let rootName = "WorldTreeDecorations"

    struct Configuration {
        var forestDensity = 0.28
        var grassDensity = 0.10
        var villageDensity = 0.04
        var treeHeightInMicroCells: CGFloat = 0.9
    }

    static func render(
        _ world: WorldState,
        in parent: SKNode,
        mapper: WorldGridMapper,
        configuration: Configuration = Configuration()
    ) {
        parent.childNode(withName: rootName)?.removeFromParent()
        let layer = SKNode()
        layer.name = rootName
        layer.zPosition = 25
        parent.addChild(layer)

        let microSize = mapper.cellSize / CGFloat(MicroBiomeGrid.dimension)
        let height = microSize * configuration.treeHeightInMicroCells
        let exclusions = world.buildingObjects.map { object in
            let dimensions = object.mapDimensions
            return CGRect(
                x: CGFloat(object.origin.x) * microSize - mapper.cellSize / 2,
                y: CGFloat(object.origin.y) * microSize - mapper.cellSize / 2,
                width: CGFloat(dimensions.width) * microSize,
                height: CGFloat(dimensions.height) * microSize
            ).insetBy(dx: -microSize, dy: -microSize)
        }

        for piece in world.pieces {
            let transform = PieceWorldTransform(piece: piece, mapper: mapper)
            for cell in piece.cellDefinitions {
                for micro in MicroGridPosition.allPositions {
                    // Split cells are excluded: they are biome boundaries.
                    guard let biome = cell.microBiomeGrid.biome(at: micro) else { continue }
                    let density: Double
                    switch biome {
                    case .darkGreenForest: density = configuration.forestDensity
                    case .naturalGrass: density = configuration.grassDensity
                    case .villageSoil: density = configuration.villageDensity
                    case .rocksalt, .hillSoil: continue
                    }
                    // Stable across rebuilds, saves, and piece movement/rotation.
                    let key = "\(piece.id)-\(cell.id.rawValue)-\(micro.x)-\(micro.y)"
                    let seed = key.utf8.reduce(UInt64(5381)) { ($0 &* 33) &+ UInt64($1) }
                    guard Double(seed % 1000) / 1000 < density else { continue }
                    let local = CGPoint(
                        x: CGFloat(cell.localPosition.x) * mapper.cellSize - mapper.cellSize / 2
                            + (CGFloat(micro.x) + 0.5) * microSize,
                        y: CGFloat(cell.localPosition.y) * mapper.cellSize + mapper.cellSize / 2
                            - (CGFloat(micro.y) + 0.5) * microSize
                    )
                    let position = transform.localToWorld(local)
                    guard !exclusions.contains(where: { $0.contains(position) }) else { continue }
                    let tree = makePlaceholderTree(height: height, variant: Int(seed % 3))
                    tree.position = position
                    // Keep trees upright when the supporting tetromino rotates.
                    tree.zPosition = -position.y / (abs(position.y) + 1000)
                    layer.addChild(tree)
                }
            }
        }
    }

    /// Replace this factory with an SKSpriteNode when the tree asset is ready.
    static func makePlaceholderTree(height: CGFloat, variant: Int) -> SKNode {
        let root = SKNode()
        root.name = "PlaceholderTree"
        let shadow = SKShapeNode(ellipseOf: CGSize(width: height * 0.55, height: height * 0.16))
        shadow.fillColor = .black.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        root.addChild(shadow)
        let trunk = SKShapeNode(rectOf: CGSize(width: height * 0.12, height: height * 0.4))
        trunk.fillColor = SKColor(red: 0.43, green: 0.29, blue: 0.16, alpha: 1)
        trunk.strokeColor = .clear
        trunk.position.y = height * 0.2
        root.addChild(trunk)
        let crown = SKShapeNode(ellipseOf: CGSize(width: height * 0.65, height: height * 0.7))
        crown.fillColor = SKColor(red: 0.18, green: 0.40 + CGFloat(variant) * 0.05, blue: 0.23, alpha: 1)
        crown.strokeColor = SKColor(red: 0.12, green: 0.29, blue: 0.16, alpha: 1)
        crown.lineWidth = 1
        crown.position.y = height * 0.65
        root.addChild(crown)
        return root
    }
}
