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
        BuildingObjectSize(width: Double(mapWidth) / 4, height: Double(mapHeight) / 4)
    }
}

enum BuildingObjectCatalog {
    // Map units are microgrid squares; ingame visuals use one quarter of the map dimensions.
    static let definitions: [BuildingObjectKind: BuildingObjectDefinition] = [
        .arthurHouse: .init(kind: .arthurHouse, title: "Rumah Arthur", mapWidth: 6, mapHeight: 4),
        .well: .init(kind: .well, title: "Sumur", mapWidth: 4, mapHeight: 4),
        .buMaraHouse: .init(kind: .buMaraHouse, title: "Rumah Bu Mara", mapWidth: 8, mapHeight: 4),
        .barn: .init(kind: .barn, title: "Lumbung", mapWidth: 6, mapHeight: 8),
        .animalPen: .init(kind: .animalPen, title: "Kandang", mapWidth: 8, mapHeight: 10),
        .annethHouse: .init(kind: .annethHouse, title: "Rumah Anneth", mapWidth: 8, mapHeight: 6),
        .rockSalt: .init(kind: .rockSalt, title: "Rock Salt Mine", mapWidth: 4, mapHeight: 5)
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
    case valid, requiresVillageSoil, requiresRockSalt, overlapsObject, placementLimitReached

    var message: String {
        switch self {
        case .valid: return "Siap dipasang"
        case .requiresVillageSoil: return "Seluruh area harus village soil utuh"
        case .requiresRockSalt: return "Seluruh area harus biome rock salt"
        case .overlapsObject: return "Area sudah ditempati objek"
        case .placementLimitReached: return "Maksimal 3 tambang rock salt"
        }
    }
}

enum TutorialBuildingPlacementResolver {
    static func target(for kind: BuildingObjectKind, in world: WorldState) -> BuildingObject? {
        if kind == .arthurHouse {
            return houseAndWellPlan(in: world)?.house
        }
        if kind == .well {
            return houseAndWellPlan(in: world)?.well
        }
        return candidates(for: kind, in: world, restrictedTo: nil).first
    }

    static func matchesTarget(_ object: BuildingObject, in world: WorldState) -> Bool {
        guard let target = target(for: object.kind, in: world) else { return false }
        return object.kind == target.kind
            && object.origin == target.origin
            && object.rotation == target.rotation
    }

    private static func houseAndWellPlan(
        in world: WorldState
    ) -> (house: BuildingObject, well: BuildingObject)? {
        let placedHouse = world.buildingObjects.first(where: { $0.kind == .arthurHouse })
        let preferredWellOrigin = GridPosition(x: -30, y: 0)

        if let placedHouse,
           let piece = supportingPiece(for: placedHouse, in: world),
           let well = candidates(for: .well, in: world, restrictedTo: piece)
            .sorted(by: { isCloser($0.origin, than: $1.origin, to: placedHouse.origin) })
            .first {
            return (placedHouse, well)
        }

        let wellPlans = world.pieces.flatMap { piece in
            candidates(for: .well, in: world, restrictedTo: piece).map { (piece, $0) }
        }.sorted {
            isCloser($0.1.origin, than: $1.1.origin, to: preferredWellOrigin)
        }

        for (piece, well) in wellPlans {
            let houses = candidates(for: .arthurHouse, in: world, restrictedTo: piece)
                .filter { $0.occupiedPositions.isDisjoint(with: well.occupiedPositions) }
                .sorted { isCloser($0.origin, than: $1.origin, to: well.origin) }
            if let house = houses.first {
                return (house, well)
            }
        }
        return nil
    }

    private static func candidates(
        for kind: BuildingObjectKind,
        in world: WorldState,
        restrictedTo piece: WorldPiece?
    ) -> [BuildingObject] {
        let validator = BuildingPlacementValidator()
        let allowedPositions: Set<GridPosition>
        if let piece {
            allowedPositions = validator.villagePositions(for: piece)
        } else {
            allowedPositions = validator.villagePositions(in: world)
        }
        let occupied = world.buildingObjects.reduce(into: Set<GridPosition>()) {
            $0.formUnion($1.occupiedPositions)
        }
        return allowedPositions.compactMap { origin in
            let object = BuildingObject(kind: kind, origin: origin, rotation: .degrees0)
            guard object.occupiedPositions.isSubset(of: allowedPositions),
                  object.occupiedPositions.isDisjoint(with: occupied) else {
                return nil
            }
            return object
        }
    }

    private static func supportingPiece(for object: BuildingObject, in world: WorldState) -> WorldPiece? {
        let validator = BuildingPlacementValidator()
        return world.pieces.first {
            object.occupiedPositions.isSubset(of: validator.villagePositions(for: $0))
        }
    }

    private static func isCloser(
        _ lhs: GridPosition,
        than rhs: GridPosition,
        to reference: GridPosition
    ) -> Bool {
        let leftX = lhs.x - reference.x
        let leftY = lhs.y - reference.y
        let rightX = rhs.x - reference.x
        let rightY = rhs.y - reference.y
        let leftDistance = leftX * leftX + leftY * leftY
        let rightDistance = rightX * rightX + rightY * rightY
        if leftDistance == rightDistance {
            return lhs.y == rhs.y ? lhs.x < rhs.x : lhs.y < rhs.y
        }
        return leftDistance < rightDistance
    }
}

struct BuildingPlacementValidator {
    func tilePositions(in world: WorldState) -> Set<GridPosition> {
        var positions = Set<GridPosition>()
        let dimension = MicroBiomeGrid.dimension
        for piece in world.pieces {
            for cell in piece.cellDefinitions {
                for microPosition in MicroGridPosition.allPositions {
                    let center = GridPosition(
                        x: cell.localPosition.x * dimension * 2 + microPosition.x * 2 + 1 - dimension,
                        y: cell.localPosition.y * dimension * 2 + dimension - microPosition.y * 2 - 1
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

    func overlapsWorldTiles(_ object: BuildingObject, in world: WorldState) -> Bool {
        !object.occupiedPositions.isDisjoint(with: tilePositions(in: world))
    }

    func villagePositions(in world: WorldState) -> Set<GridPosition> {
        biomePositions(.villageSoil, in: world)
    }

    func villagePositions(for piece: WorldPiece) -> Set<GridPosition> {
        biomePositions(.villageSoil, for: piece)
    }

    func biomePositions(_ biome: BiomeType, in world: WorldState) -> Set<GridPosition> {
        world.pieces.reduce(into: Set<GridPosition>()) { positions, piece in
            positions.formUnion(biomePositions(biome, for: piece))
        }
    }

    func biomePositions(_ biome: BiomeType, for piece: WorldPiece) -> Set<GridPosition> {
        var positions = Set<GridPosition>()
        let dimension = MicroBiomeGrid.dimension
        for cell in piece.cellDefinitions {
            // Saved worlds can contain an older serialized microgrid. For the
            // built-in puzzle cells, always validate against the current fixture
            // used by the visible tile artwork, without requiring a save reset.
            let microBiomeGrid = BuildingPuzzleCellID(rawValue: cell.id.rawValue)
                .map { BuildingPuzzleBiomeFixture.grid(for: $0) }
                ?? cell.microBiomeGrid
            // A split micro-cell contains two biomes, so it is not a complete
            // buildable square for either one. Buildings may only occupy cells
            // whose entire area is the required biome.
            for microCell in microBiomeGrid.cells() where microCell.biome == biome {
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
        return positions
    }

    func validate(_ object: BuildingObject, in world: WorldState) -> BuildingPlacementResult {
        let requiredBiome: BiomeType = object.kind == .rockSalt ? .rocksalt : .villageSoil
        guard object.occupiedPositions.isSubset(of: biomePositions(requiredBiome, in: world)) else {
            return object.kind == .rockSalt ? .requiresRockSalt : .requiresVillageSoil
        }
        if object.kind == .rockSalt,
           world.buildingObjects.filter({ $0.kind == .rockSalt && $0.id != object.id }).count >= 3 {
            return .placementLimitReached
        }
        guard world.buildingObjects.filter({ $0.id != object.id }).allSatisfy({
            $0.occupiedPositions.isDisjoint(with: object.occupiedPositions)
        }) else { return .overlapsObject }
        return .valid
    }

    func supportsExistingObjects(in world: WorldState) -> Bool {
        guard !world.buildingObjects.isEmpty else { return true }
        let village = villagePositions(in: world)
        let rockSalt = biomePositions(.rocksalt, in: world)
        return world.buildingObjects.allSatisfy {
            $0.occupiedPositions.isSubset(of: $0.kind == .rockSalt ? rockSalt : village)
        }
    }
}
