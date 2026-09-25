import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

struct TileAssetResolver {
    static func node(
        biome: BiomeType?,
        split: MicroBiomeSplit?,
        size: CGFloat
    ) -> SKNode {
        guard let split else {
            return spriteNode(for: biome, size: size)
        }

        let node = SKNode()
        let half = size / 2
        let corners = [
            CGPoint(x: -half, y: half),
            CGPoint(x: half, y: half),
            CGPoint(x: half, y: -half),
            CGPoint(x: -half, y: -half)
        ]
        let primary = split.primaryCorner.rawValue
        let secondary = (primary + 2) % 4

        for (corner, biome) in [(primary, split.primaryBiome), (secondary, split.secondaryBiome)] {
            let path = CGMutablePath()
            path.move(to: corners[corner])
            path.addLine(to: corners[(corner + 1) % 4])
            path.addLine(to: corners[(corner + 3) % 4])
            path.closeSubpath()

            let triangle = SKShapeNode(path: path)
            triangle.fillColor = biome.debugColor
            triangle.strokeColor = .clear
            triangle.lineWidth = 0
            triangle.isAntialiased = false
            node.addChild(triangle)
        }
        return node
    }

    static func spriteNode(for biome: BiomeType?, size: CGFloat) -> SKSpriteNode {
        guard let biome else {
            return SKSpriteNode(color: .clear, size: CGSize(width: size, height: size))
        }

        if let texture = texture(for: biome) {
            let sprite = SKSpriteNode(texture: texture, color: .clear, size: CGSize(width: size, height: size))
            sprite.texture?.filteringMode = .nearest
            return sprite
        }

        return SKSpriteNode(color: biome.debugColor, size: CGSize(width: size, height: size))
    }

    static func texture(for biome: BiomeType) -> SKTexture? {
        #if canImport(UIKit)
        guard UIImage(named: assetName(for: biome)) != nil else {
            return nil
        }
        #endif
        let texture = SKTexture(imageNamed: assetName(for: biome))
        texture.filteringMode = .nearest
        return texture
    }

    static func assetName(for biome: BiomeType) -> String {
        switch biome {
        case .rocksalt:
            return "tile_rocksalt"
        case .villageSoil:
            return "tile_village_soil"
        case .naturalGrass:
            return "tile_natural_grass"
        case .darkGreenForest:
            return "tile_dark_green_forest"
        case .hillSoil:
            return "tile_hill_soil"
        }
    }
}
