import SpriteKit

/// Selects authored image overrides for specific complete tiles. Biomes remain
/// gameplay data; this is only for tiles that need hand-authored visuals.
struct TileAssetResolver {
    struct TileOverride {
        let assetName: String
        let rotation: CGFloat
        let isMirroredHorizontally: Bool
        let isMirroredVertically: Bool

        init(
            assetName: String,
            rotation: CGFloat = 0,
            isMirroredHorizontally: Bool = false,
            isMirroredVertically: Bool = false
        ) {
            self.assetName = assetName
            self.rotation = rotation
            self.isMirroredHorizontally = isMirroredHorizontally
            self.isMirroredVertically = isMirroredVertically
        }
    }

    static func override(for piece: WorldPiece, gridID: GridID) -> TileOverride? {
        switch piece.role {
        case .z1:
            return firstITileOverride(for: gridID)
        case .z2:
            return secondITileOverride(for: gridID)
        case .l1:
            return lTileOverride(for: gridID)
        case .village, .forestWest, .forestEast, .forestPass, .hill, .outerWilderness, .t1, .s1:
            return nil
        }
    }

    static func overrideNode(for override: TileOverride, size: CGFloat) -> SKNode {
        let texture = SKTexture(imageNamed: override.assetName)
        texture.filteringMode = .linear
        let sprite = SKSpriteNode(texture: texture, color: .clear, size: CGSize(width: size, height: size))
        sprite.zRotation = override.rotation
        if override.isMirroredHorizontally {
            sprite.xScale = -1
        }
        if override.isMirroredVertically {
            sprite.yScale = -1
        }
        return sprite
    }

    private static func firstITileOverride(for gridID: GridID) -> TileOverride? {
        switch gridID.rawValue {
        case "A":
            return TileOverride(assetName: "tile 5")
        case "B":
            return TileOverride(assetName: "tile 5")
        case "C":
            return TileOverride(assetName: "tile 2", isMirroredHorizontally: true)
        case "D":
            return TileOverride(assetName: "tile 3")
        default:
            return nil
        }
    }

    private static func secondITileOverride(for gridID: GridID) -> TileOverride? {
        switch gridID.rawValue {
        case "E":
            return TileOverride(assetName: "tile 1", isMirroredVertically: true)
        case "F":
            return TileOverride(assetName: "tile 2")
        case "G":
            return TileOverride(assetName: "tile 1", rotation: -.pi / 2)
        case "H":
            return TileOverride(assetName: "tile 3")
        default:
            return nil
        }
    }

    private static func lTileOverride(for gridID: GridID) -> TileOverride? {
        switch gridID.rawValue {
        case "I":
            return TileOverride(assetName: "tile 1")
        case "J":
            return TileOverride(assetName: "tile 4", rotation: -.pi)
        case "K":
            return TileOverride(
                assetName: "tile 4",
                rotation: -.pi / 2,
                isMirroredHorizontally: true,
                isMirroredVertically: true
            )
        case "L":
            return TileOverride(assetName: "tile 4")
        default:
            return nil
        }
    }
}
