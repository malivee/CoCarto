import Foundation

enum VillageSoilFootprintDebugTarget: CaseIterable, Sendable {
    case threeByThree
    case sixBySix
    case sixByNine
    case nineByFifteen

    var title: String {
        switch self {
        case .threeByThree:
            return "3x3"
        case .sixBySix:
            return "6x6"
        case .sixByNine:
            return "6x9"
        case .nineByFifteen:
            return "9x15"
        }
    }

    var dimensions: (width: Int, height: Int) {
        switch self {
        case .threeByThree:
            return (3, 3)
        case .sixBySix:
            return (6, 6)
        case .sixByNine:
            return (6, 9)
        case .nineByFifteen:
            return (9, 15)
        }
    }
}

struct VillageSoilFootprintScanner: Sendable {
    func findRectangle(width: Int, height: Int, in worldState: WorldState) -> GlobalMicroRectangle? {
        findAllRectangles(width: width, height: height, in: worldState).first
    }

    func findRectangleAllowingRotation(width: Int, height: Int, in worldState: WorldState) -> GlobalMicroRectangle? {
        if let rectangle = findRectangle(width: width, height: height, in: worldState) {
            return rectangle
        }
        guard width != height else {
            return nil
        }
        return findRectangle(width: height, height: width, in: worldState)
    }

    func findAllRectangles(width: Int, height: Int, in worldState: WorldState) -> [GlobalMicroRectangle] {
        guard width > 0, height > 0 else {
            return []
        }

        let terrain = worldState.microTerrainMap()
        let villagePositions = Set(terrain.compactMap { position, cell in
            cell.biome == .villageSoil ? position : nil
        })
        guard let bounds = MicroTerrainBounds(positions: Array(terrain.keys)) else {
            return []
        }

        let maxOriginX = bounds.maxX - width + 1
        let maxOriginY = bounds.maxY - height + 1
        guard maxOriginX >= bounds.minX, maxOriginY >= bounds.minY else {
            return []
        }

        var rectangles: [GlobalMicroRectangle] = []
        for y in bounds.minY...maxOriginY {
            for x in bounds.minX...maxOriginX {
                let origin = GlobalMicroPosition(x: x, y: y)
                let rectangle = GlobalMicroRectangle(origin: origin, width: width, height: height)
                if rectangle.positions().allSatisfy({ villagePositions.contains($0) }) {
                    rectangles.append(rectangle)
                }
            }
        }
        return rectangles
    }

    func largestRectangle(in worldState: WorldState) -> GlobalMicroRectangle? {
        let terrain = worldState.microTerrainMap()
        let villagePositions = Set(terrain.compactMap { position, cell in
            cell.biome == .villageSoil ? position : nil
        })
        guard let bounds = MicroTerrainBounds(positions: Array(terrain.keys)) else {
            return nil
        }

        let columnCount = bounds.maxX - bounds.minX + 1
        var heights = Array(repeating: 0, count: columnCount)
        var best: GlobalMicroRectangle?

        for y in bounds.minY...bounds.maxY {
            for column in 0..<columnCount {
                let x = bounds.minX + column
                if villagePositions.contains(GlobalMicroPosition(x: x, y: y)) {
                    heights[column] += 1
                } else {
                    heights[column] = 0
                }
            }

            var stack: [Int] = []
            for index in 0...columnCount {
                let currentHeight = index == columnCount ? 0 : heights[index]
                while let last = stack.last, heights[last] > currentHeight {
                    let height = heights[stack.removeLast()]
                    let leftBoundary = stack.last.map { $0 + 1 } ?? 0
                    let width = index - leftBoundary
                    let origin = GlobalMicroPosition(
                        x: bounds.minX + leftBoundary,
                        y: y - height + 1
                    )
                    let rectangle = GlobalMicroRectangle(origin: origin, width: width, height: height)
                    if rectangle.area > (best?.area ?? 0) {
                        best = rectangle
                    }
                }
                stack.append(index)
            }
        }

        return best
    }

    func biomeStatistics(in worldState: WorldState) -> [BiomeType: Int] {
        worldState.microTerrainMap().values.reduce(into: [:]) { counts, cell in
            if let biome = cell.biome {
                counts[biome, default: 0] += 1
            }
        }
    }
}

private struct MicroTerrainBounds {
    let minX: Int
    let maxX: Int
    let minY: Int
    let maxY: Int

    init?(positions: [GlobalMicroPosition]) {
        guard let first = positions.first else {
            return nil
        }
        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y

        for position in positions.dropFirst() {
            minX = min(minX, position.x)
            maxX = max(maxX, position.x)
            minY = min(minY, position.y)
            maxY = max(maxY, position.y)
        }

        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }
}
