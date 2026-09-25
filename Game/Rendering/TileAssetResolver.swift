import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

/// Selects one authored image for the complete large tile. Biomes remain gameplay
/// data and never select individual texture fragments.
struct TileAssetResolver {
    private struct Selection {
        let assetName: String
        let rotation: CGFloat
    }

    static func node(for grid: MicroBiomeGrid, size: CGFloat) -> SKNode {
        let selection = selection(for: grid)
        #if canImport(UIKit)
        guard UIImage(named: selection.assetName) != nil else {
            return fallbackNode(for: grid, size: size)
        }
        #endif
        let texture = SKTexture(imageNamed: selection.assetName)
        texture.filteringMode = .linear
        let sprite = SKSpriteNode(texture: texture, color: .clear, size: CGSize(width: size, height: size))
        sprite.zRotation = selection.rotation
        return sprite
    }

    private static func selection(for grid: MicroBiomeGrid) -> Selection {
        let cells = grid.cells().compactMap { cell -> (MicroGridPosition, BiomeType)? in
            cell.biome.map { (cell.localPosition, $0) }
        }
        let biomes = Set(cells.map(\.1))
        if biomes == [.villageSoil] { return Selection(assetName: "tile 3", rotation: 0) }
        if biomes == [.rocksalt] { return Selection(assetName: "tile 5", rotation: 0) }
        if biomes.contains(.darkGreenForest) || biomes.contains(.naturalGrass) {
            let biome: BiomeType = biomes.contains(.darkGreenForest) ? .darkGreenForest : .naturalGrass
            return Selection(assetName: "tile 4", rotation: diagonalRotation(of: biome, in: cells, base: .bottomLeft))
        }
        if isCenteredTriangle(of: .rocksalt, in: cells) {
            return Selection(assetName: "tile 1", rotation: centeredTriangleRotation(of: .rocksalt, in: cells))
        }
        return Selection(assetName: "tile 2", rotation: diagonalRotation(of: .rocksalt, in: cells, base: .topRight))
    }

    private enum Quadrant: Int { case topRight, topLeft, bottomLeft, bottomRight }

    private static func diagonalRotation(
        of biome: BiomeType,
        in cells: [(MicroGridPosition, BiomeType)],
        base: Quadrant
    ) -> CGFloat {
        let samples = cells.filter { $0.1 == biome }
        guard !samples.isEmpty else { return 0 }
        let center = Double(MicroBiomeGrid.dimension - 1) / 2
        let averageX = samples.map { Double($0.0.x) }.reduce(0, +) / Double(samples.count)
        let averageY = samples.map { Double($0.0.y) }.reduce(0, +) / Double(samples.count)
        let target: Quadrant
        if averageY < center {
            target = averageX < center ? .topLeft : .topRight
        } else {
            target = averageX < center ? .bottomLeft : .bottomRight
        }
        return CGFloat(target.rawValue - base.rawValue) * .pi / 2
    }

    private static func positions(
        of biome: BiomeType,
        in cells: [(MicroGridPosition, BiomeType)]
    ) -> [MicroGridPosition] {
        cells.filter { $0.1 == biome }.map(\.0)
    }

    private static func isCenteredTriangle(
        of biome: BiomeType,
        in cells: [(MicroGridPosition, BiomeType)]
    ) -> Bool {
        let samples = positions(of: biome, in: cells)
        guard !samples.isEmpty else { return false }
        let center = Double(MicroBiomeGrid.dimension - 1) / 2
        let averageX = samples.map { Double($0.x) }.reduce(0, +) / Double(samples.count)
        let averageY = samples.map { Double($0.y) }.reduce(0, +) / Double(samples.count)
        return abs(averageX - center) < 0.35 || abs(averageY - center) < 0.35
    }

    private static func centeredTriangleRotation(
        of biome: BiomeType,
        in cells: [(MicroGridPosition, BiomeType)]
    ) -> CGFloat {
        let samples = positions(of: biome, in: cells)
        let center = Double(MicroBiomeGrid.dimension - 1) / 2
        let averageX = samples.map { Double($0.x) }.reduce(0, +) / Double(samples.count)
        let averageY = samples.map { Double($0.y) }.reduce(0, +) / Double(samples.count)
        if abs(averageX - center) < abs(averageY - center) {
            return averageY > center ? 0 : .pi
        }
        return averageX > center ? .pi / 2 : -.pi / 2
    }

    private static func fallbackNode(for grid: MicroBiomeGrid, size: CGFloat) -> SKNode {
        let dominant = grid.cells().compactMap(\.biome).first
        return SKSpriteNode(color: dominant?.debugColor ?? .clear, size: CGSize(width: size, height: size))
    }
}
