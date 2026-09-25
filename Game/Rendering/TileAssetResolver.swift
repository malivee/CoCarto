import SpriteKit

/// Selects authored image overrides for specific complete tiles. Biomes remain
/// gameplay data; this is only for tiles that need hand-authored visuals.
struct TileAssetResolver {
    /// Base tiles are used on the map; their detailed counterparts are used in
    /// the world while keeping the same rotation and mirroring configuration.
    private static let detailAssetByTileAsset: [String: String] = [
        "tile 1": "tileDetail 1",
        "tile 2": "tileDetail 2",
        "tile 3": "tileDetail 3",
        "tile 4": "tileDetail 4",
        "tile 5": "tileDetail 5"
    ]

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

    static func overrideNode(for override: TileOverride, size: CGFloat, usesDetailAsset: Bool = false) -> SKNode {
        let resolvedAssetName = usesDetailAsset
            ? detailAssetByTileAsset[override.assetName] ?? override.assetName
            : override.assetName
        let texture = SKTexture(imageNamed: resolvedAssetName)
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

    static func shadowNode(size: CGFloat) -> SKNode {
        let shadow = SKShapeNode(rectOf: CGSize(width: size * 1.16, height: size * 1.14), cornerRadius: size * 0.07)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.24)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: size * 0.055, y: -size * 0.065)
        shadow.zPosition = 0.44
        return shadow
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
