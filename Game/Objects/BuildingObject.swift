import Foundation

enum BuildingObjectKind: String, CaseIterable, Codable, Sendable {
    case arthurHouse, well, buMaraHouse, barn, animalPen, annethHouse, rockSalt
}

struct BuildingObjectSize: Equatable, Sendable {
    let width: Double
    let height: Double
}

struct BuildingObjectDefinition: Sendable {
    let kind: BuildingObjectKind
    let title: String
    let mapWidth: Int
    let mapHeight: Int

    var worldSize: BuildingObjectSize {
        BuildingObjectSize(width: Double(mapWidth) / 2, height: Double(mapHeight) / 2)
    }
}

enum BuildingObjectCatalog {
    // Map units are microgrid squares; one World unit equals two Map units.
    static let definitions: [BuildingObjectKind: BuildingObjectDefinition] = [
        .arthurHouse: .init(kind: .arthurHouse, title: "Rumah Arthur", mapWidth: 6, mapHeight: 4),
        .well: .init(kind: .well, title: "Sumur", mapWidth: 4, mapHeight: 4),
        .buMaraHouse: .init(kind: .buMaraHouse, title: "Rumah Bu Mara", mapWidth: 8, mapHeight: 4),
        .barn: .init(kind: .barn, title: "Lumbung", mapWidth: 6, mapHeight: 4),
        .animalPen: .init(kind: .animalPen, title: "Kandang", mapWidth: 8, mapHeight: 10),
        .annethHouse: .init(kind: .annethHouse, title: "Rumah Anneth", mapWidth: 8, mapHeight: 6),
        .rockSalt: .init(kind: .rockSalt, title: "Rock Salt", mapWidth: 4, mapHeight: 5)
    ]

    static func definition(for kind: BuildingObjectKind) -> BuildingObjectDefinition {
        definitions[kind]!
    }
}

struct BuildingObject: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    let kind: BuildingObjectKind
    // Bottom-left microgrid square in the same upward-Y coordinates as the map.
    let origin: GridPosition
    let rotation: GridRotation

    var mapDimensions: (width: Int, height: Int) {
        let definition = BuildingObjectCatalog.definition(for: kind)
        return rotation == .degrees90 || rotation == .degrees270
            ? (definition.mapHeight, definition.mapWidth)
            : (definition.mapWidth, definition.mapHeight)
    }

    var occupiedPositions: Set<GridPosition> {
        let size = mapDimensions
        return Set((0..<size.height).flatMap { y in
            (0..<size.width).map { x in GridPosition(x: origin.x + x, y: origin.y + y) }
        })
    }
}

enum BuildingPlacementResult: Equatable {
    case valid, requiresVillageSoil, overlapsObject

    var message: String {
        switch self {
        case .valid: return "Siap dipasang"
        case .requiresVillageSoil: return "Seluruh area harus village soil utuh"
        case .overlapsObject: return "Area sudah ditempati objek"
        }
    }
}

struct BuildingPlacementValidator {
    func villagePositions(in world: WorldState) -> Set<GridPosition> {
        var positions = Set<GridPosition>()
        let dimension = MicroBiomeGrid.dimension
        for piece in world.pieces {
            for cell in piece.cellDefinitions {
                for microCell in cell.microBiomeGrid.cells() where microCell.biome == .villageSoil {
                    // Rotate actual rendered square centers, including the downward microgrid Y.
                    let center = GridPosition(
                        x: cell.localPosition.x * dimension * 2 + microCell.localPosition.x * 2 + 1 - dimension,
                        y: cell.localPosition.y * dimension * 2 + dimension - microCell.localPosition.y * 2 - 1
                    )
                    let rotated = piece.rotation.rotated(center)
                    positions.insert(GridPosition(
                        x: piece.gridPosition.x * dimension + (rotated.x + dimension - 1) / 2,
                        y: piece.gridPosition.y * dimension + (rotated.y + dimension - 1) / 2
                    ))
                }
            }
        }
        return positions
    }

    func validate(_ object: BuildingObject, in world: WorldState) -> BuildingPlacementResult {
        guard object.occupiedPositions.isSubset(of: villagePositions(in: world)) else {
            return .requiresVillageSoil
        }
        guard world.buildingObjects.filter({ $0.id != object.id }).allSatisfy({
            $0.occupiedPositions.isDisjoint(with: object.occupiedPositions)
        }) else { return .overlapsObject }
        return .valid
    }

    func supportsExistingObjects(in world: WorldState) -> Bool {
        guard !world.buildingObjects.isEmpty else { return true }
        let village = villagePositions(in: world)
        return world.buildingObjects.allSatisfy { $0.occupiedPositions.isSubset(of: village) }
    }
}
