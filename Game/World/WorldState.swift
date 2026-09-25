import Foundation

struct WorldState: Codable, Equatable, Sendable {
    private(set) var pieces: [WorldPiece]
    private(set) var landmarks: [WorldLandmark]
    private(set) var buildingObjects: [BuildingObject]

    init(pieces: [WorldPiece], landmarks: [WorldLandmark] = Self.initialLandmarks, buildingObjects: [BuildingObject] = []) {
        self.pieces = pieces
        self.landmarks = landmarks
        self.buildingObjects = buildingObjects
    }

    private enum CodingKeys: String, CodingKey { case pieces, landmarks, buildingObjects }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pieces = try container.decode([WorldPiece].self, forKey: .pieces)
        landmarks = try container.decode([WorldLandmark].self, forKey: .landmarks)
        buildingObjects = try container.decodeIfPresent([BuildingObject].self, forKey: .buildingObjects) ?? []
    }

    @discardableResult
    mutating func placeBuildingObject(_ object: BuildingObject) -> BuildingPlacementResult {
        let result = BuildingPlacementValidator().validate(object, in: self)
        guard result == .valid else { return result }
        guard !buildingObjects.contains(where: { $0.id == object.id }) else { return .overlapsObject }
        guard object.kind == .rockSalt || !buildingObjects.contains(where: { $0.kind == object.kind }) else {
            return .overlapsObject
        }
        buildingObjects.append(object)
        return .valid
    }

    func buildingObject(id: UUID) -> BuildingObject? {
        buildingObjects.first { $0.id == id }
    }

    @discardableResult
    mutating func removeBuildingObject(id: UUID) -> BuildingObject? {
        guard let index = buildingObjects.firstIndex(where: { $0.id == id }) else { return nil }
        return buildingObjects.remove(at: index)
    }

    var occupancy: GridOccupancy {
        GridOccupancy(worldState: self)
    }

    func piece(id: UUID) -> WorldPiece? {
        pieces.first { $0.id == id }
    }

    func piece(role: PieceRole) -> WorldPiece? {
        pieces.first { $0.role == role }
    }

    func landmark(id: LandmarkID) -> WorldLandmark? {
        landmarks.first { $0.id == id }
    }

    @discardableResult
    mutating func setLandmarkState(_ state: LandmarkState, for id: LandmarkID) -> Bool {
        guard let index = landmarks.firstIndex(where: { $0.id == id }) else {
            return false
        }

        landmarks[index].state = state
        return true
    }

    mutating func movePiece(
        id: UUID,
        to position: GridPosition,
        rotation: GridRotation
    ) -> Bool {
        let validator = PlacementValidator()
        guard validator.canPlace(pieceID: id, at: position, rotation: rotation, in: self),
              let index = pieces.firstIndex(where: { $0.id == id }),
              canMovePieceWithBuildings(pieceID: id) else {
            return false
        }

        let originalPiece = pieces[index]
        let movedObjects = transformedBuildingObjects(
            with: originalPiece,
            to: position,
            rotation: rotation
        )
        pieces[index].gridPosition = position
        pieces[index].rotation = rotation
        for movedObject in movedObjects {
            guard let objectIndex = buildingObjects.firstIndex(where: { $0.id == movedObject.id }) else {
                continue
            }
            buildingObjects[objectIndex] = movedObject
        }
        return true
    }

    @discardableResult
    mutating func setPieceMovable(_ isMovable: Bool, for role: PieceRole) -> Bool {
        guard let index = pieces.firstIndex(where: { $0.role == role }),
              pieces[index].isMovable != isMovable else {
            return false
        }
        pieces[index].isMovable = isMovable
        return true
    }

    func previewingPiece(id: UUID, at position: GridPosition, rotation: GridRotation) -> WorldState {
        guard let index = pieces.firstIndex(where: { $0.id == id }) else {
            return self
        }
        var previewWorld = self
        let originalPiece = pieces[index]
        let movedObjects = transformedBuildingObjects(
            with: originalPiece,
            to: position,
            rotation: rotation
        )
        previewWorld.pieces[index].gridPosition = position
        previewWorld.pieces[index].rotation = rotation
        for movedObject in movedObjects {
            guard let objectIndex = previewWorld.buildingObjects.firstIndex(where: { $0.id == movedObject.id }) else {
                continue
            }
            previewWorld.buildingObjects[objectIndex] = movedObject
        }
        return previewWorld
    }

    func canMovePieceWithBuildings(pieceID: UUID) -> Bool {
        guard let piece = piece(id: pieceID) else { return false }
        let validator = BuildingPlacementValidator()
        let villagePositions = validator.villagePositions(for: piece)
        let rockSaltPositions = validator.biomePositions(.rocksalt, for: piece)

        return buildingObjects.allSatisfy { object in
            let supportedPositions = object.kind == .rockSalt ? rockSaltPositions : villagePositions
            let touchesPiece = !object.occupiedPositions.isDisjoint(with: supportedPositions)
            return !touchesPiece || object.occupiedPositions.isSubset(of: supportedPositions)
        }
    }

    func buildingObjectsSupported(byPieceID pieceID: UUID) -> [BuildingObject] {
        guard let piece = piece(id: pieceID) else { return [] }
        let validator = BuildingPlacementValidator()
        let villagePositions = validator.villagePositions(for: piece)
        let rockSaltPositions = validator.biomePositions(.rocksalt, for: piece)
        return buildingObjects.filter { object in
            let supportedPositions = object.kind == .rockSalt ? rockSaltPositions : villagePositions
            return object.occupiedPositions.isSubset(of: supportedPositions)
        }
    }

    func hasBuildingObject(onPieceID pieceID: UUID) -> Bool {
        guard let piece = piece(id: pieceID) else { return false }
        let validator = BuildingPlacementValidator()
        let villagePositions = validator.villagePositions(for: piece)
        let rockSaltPositions = validator.biomePositions(.rocksalt, for: piece)
        return buildingObjects.contains { object in
            let supportedPositions = object.kind == .rockSalt ? rockSaltPositions : villagePositions
            return !object.occupiedPositions.isDisjoint(with: supportedPositions)
        }
    }

    private func transformedBuildingObjects(
        with piece: WorldPiece,
        to position: GridPosition,
        rotation: GridRotation
    ) -> [BuildingObject] {
        let validator = BuildingPlacementValidator()
        let villagePositions = validator.villagePositions(for: piece)
        let rockSaltPositions = validator.biomePositions(.rocksalt, for: piece)
        let dimension = MicroBiomeGrid.dimension
        let oldAnchor = GridPosition(
            x: piece.gridPosition.x * dimension,
            y: piece.gridPosition.y * dimension
        )
        let newAnchor = GridPosition(x: position.x * dimension, y: position.y * dimension)
        let rotationDelta = Self.rotationDelta(from: piece.rotation, to: rotation)

        return buildingObjects.compactMap { object in
            let supportedPositions = object.kind == .rockSalt ? rockSaltPositions : villagePositions
            guard object.occupiedPositions.isSubset(of: supportedPositions) else { return nil }

            let transformedPositions = object.occupiedPositions.map { globalPosition -> GridPosition in
                let oldRotatedCenter = GridPosition(
                    x: 2 * (globalPosition.x - oldAnchor.x) - (dimension - 1),
                    y: 2 * (globalPosition.y - oldAnchor.y) - (dimension - 1)
                )
                let localCenter = piece.rotation.inverse.rotated(oldRotatedCenter)
                let newRotatedCenter = rotation.rotated(localCenter)
                return GridPosition(
                    x: newAnchor.x + (newRotatedCenter.x + dimension - 1) / 2,
                    y: newAnchor.y + (newRotatedCenter.y + dimension - 1) / 2
                )
            }
            guard let minX = transformedPositions.map(\.x).min(),
                  let minY = transformedPositions.map(\.y).min() else {
                return nil
            }
            return BuildingObject(
                id: object.id,
                kind: object.kind,
                origin: GridPosition(x: minX, y: minY),
                rotation: Self.combined(object.rotation, with: rotationDelta)
            )
        }
    }

    private static func rotationDelta(from original: GridRotation, to proposed: GridRotation) -> GridRotation {
        let value = (proposed.rawValue - original.rawValue + 360) % 360
        return GridRotation(rawValue: value) ?? .degrees0
    }

    private static func combined(_ rotation: GridRotation, with delta: GridRotation) -> GridRotation {
        GridRotation(rawValue: (rotation.rawValue + delta.rawValue) % 360) ?? rotation
    }

    @discardableResult
    mutating func synchronizePuzzlePieces(allowing roles: Set<PieceRole>, from prototype: WorldState = .buildingPuzzleBiomePrototype) -> Bool {
        let progressionRoles = Set(prototype.pieces.map(\.role))
        let originalPieces = pieces
        pieces.removeAll { piece in
            progressionRoles.contains(piece.role) && !roles.contains(piece.role)
        }
        for prototypePiece in prototype.pieces where roles.contains(prototypePiece.role) {
            guard !pieces.contains(where: { $0.id == prototypePiece.id }) else {
                continue
            }
            pieces.append(prototypePiece)
        }
        return pieces != originalPieces
    }
}

extension WorldState {
    static let initialLandmarks = [
        WorldLandmark(
            id: .outerExit,
            pieceRole: .outerWilderness,
            localCell: GridPosition(x: 3, y: 0),
            state: .inactive
        )
    ]

    // Prototype solution:
    // C / Forest East -> position (2, 0), rotation 0
    // D / Forest Pass -> position (5, 1), rotation 270
    // This creates a traversable Village -> Forest East -> Forest Pass -> Outer Wilderness route.
    static let playablePuzzlePrototype = WorldState(pieces: [
        WorldPiece(
            id: PieceIDs.village,
            type: .o,
            role: .village,
            gridPosition: GridPosition(x: 0, y: 0),
            rotation: .degrees0,
            isMovable: false,
            cellDefinitions: EdgeProfiles.openO
        ),
        WorldPiece(
            id: PieceIDs.forestWest,
            type: .s,
            role: .forestWest,
            gridPosition: GridPosition(x: -4, y: -3),
            rotation: .degrees0,
            isMovable: true,
            cellDefinitions: EdgeProfiles.openS
        ),
        WorldPiece(
            id: PieceIDs.forestEast,
            type: .z,
            role: .forestEast,
            gridPosition: GridPosition(x: 4, y: -4),
            rotation: .degrees0,
            isMovable: true,
            cellDefinitions: EdgeProfiles.openZ
        ),
        WorldPiece(
            id: PieceIDs.forestPass,
            type: .l,
            role: .forestPass,
            gridPosition: GridPosition(x: 0, y: -4),
            rotation: .degrees0,
            isMovable: true,
            cellDefinitions: EdgeProfiles.openL
        ),
        WorldPiece(
            id: PieceIDs.hill,
            type: .t,
            role: .hill,
            gridPosition: GridPosition(x: -1, y: 4),
            rotation: .degrees0,
            isMovable: true,
            cellDefinitions: EdgeProfiles.openT
        ),
        WorldPiece(
            id: PieceIDs.outerWilderness,
            type: .i,
            role: .outerWilderness,
            gridPosition: GridPosition(x: 8, y: 0),
            rotation: .degrees0,
            isMovable: false,
            cellDefinitions: EdgeProfiles.openI
        )
    ])

    static let initialGraybox = WorldState(pieces: [
        WorldPiece(
            id: PieceIDs.village,
            type: .o,
            role: .village,
            gridPosition: GridPosition(x: 0, y: 0),
            rotation: .degrees0,
            isMovable: false,
            cellDefinitions: EdgeProfiles.village
        ),
        WorldPiece(
            id: PieceIDs.forestWest,
            type: .s,
            role: .forestWest,
            gridPosition: GridPosition(x: -3, y: 0),
            rotation: .degrees0,
            isMovable: true,
            cellDefinitions: EdgeProfiles.forestWest
        ),
        WorldPiece(
            id: PieceIDs.forestEast,
            type: .z,
            role: .forestEast,
            gridPosition: GridPosition(x: 4, y: 0),
            rotation: .degrees0,
            isMovable: true,
            cellDefinitions: EdgeProfiles.forestEast
        ),
        WorldPiece(
            id: PieceIDs.forestPass,
            type: .l,
            role: .forestPass,
            gridPosition: GridPosition(x: 0, y: -4),
            rotation: .degrees0,
            isMovable: true,
            cellDefinitions: EdgeProfiles.forestPass
        ),
        WorldPiece(
            id: PieceIDs.hill,
            type: .t,
            role: .hill,
            gridPosition: GridPosition(x: 0, y: -7),
            rotation: .degrees0,
            isMovable: true,
            cellDefinitions: EdgeProfiles.hill
        ),
        WorldPiece(
            id: PieceIDs.outerWilderness,
            type: .i,
            role: .outerWilderness,
            gridPosition: GridPosition(x: 0, y: 4),
            rotation: .degrees0,
            isMovable: false,
            cellDefinitions: EdgeProfiles.outerWilderness
        )
    ])
}

private enum EdgeProfiles {
    static let openI = [
        cell(0, 0, .open, biome: .rocksalt),
        cell(1, 0, .open, biome: .rocksalt),
        cell(2, 0, .open, biome: .rocksalt),
        cell(3, 0, .open, biome: .rocksalt)
    ]

    static let openO = [
        cell(0, 0, .open, biome: .villageSoil),
        cell(1, 0, .open, biomeEdges: CellBiomeEdges(north: .villageSoil, east: .naturalGrass, south: .naturalGrass, west: .villageSoil)),
        cell(0, 1, .open, biome: .villageSoil),
        cell(1, 1, .open, biome: .villageSoil)
    ]

    static let openT = [
        cell(-1, 0, .open, biome: .hillSoil),
        cell(0, 0, .open, biome: .hillSoil),
        cell(1, 0, .open, biome: .hillSoil),
        cell(0, 1, .open, biome: .hillSoil)
    ]

    static let openL = [
        cell(0, 0, .open, biome: .darkGreenForest),
        cell(0, 1, .open, biome: .darkGreenForest),
        cell(0, 2, .open, biome: .naturalGrass),
        cell(1, 2, .open, biome: .darkGreenForest)
    ]

    static let openS = [
        cell(1, 0, .open, biome: .darkGreenForest),
        cell(2, 0, .open, biome: .darkGreenForest),
        cell(0, 1, .open, biome: .naturalGrass),
        cell(1, 1, .open, biome: .darkGreenForest)
    ]

    static let openZ = [
        cell(0, 0, .open, biome: .darkGreenForest),
        cell(1, 0, .open, biome: .darkGreenForest),
        cell(1, 1, .open, biome: .naturalGrass),
        cell(2, 1, .open, biome: .darkGreenForest)
    ]

    static let village = [
        cell(0, 0, .open, biome: .villageSoil),
        cell(1, 0, CellEdges(north: .open, east: .path, south: .open, west: .open), biomeEdges: CellBiomeEdges(north: .villageSoil, east: .naturalGrass, south: .naturalGrass, west: .villageSoil)),
        cell(0, 1, .open, biome: .villageSoil),
        cell(1, 1, .open, biome: .villageSoil)
    ]

    static let forestWest = [
        cell(1, 0, CellEdges(north: .forest, east: .path, south: .open, west: .forest), biome: .darkGreenForest),
        cell(2, 0, CellEdges(north: .forest, east: .path, south: .path, west: .path), biome: .darkGreenForest),
        cell(0, 1, CellEdges(north: .forest, east: .path, south: .forest, west: .forest), biome: .naturalGrass),
        cell(1, 1, CellEdges(north: .open, east: .forest, south: .path, west: .path), biome: .darkGreenForest)
    ]

    static let forestEast = [
        cell(0, 0, CellEdges(north: .forest, east: .path, south: .open, west: .forest), biome: .darkGreenForest),
        cell(1, 0, CellEdges(north: .forest, east: .forest, south: .path, west: .path), biome: .darkGreenForest),
        cell(1, 1, CellEdges(north: .open, east: .path, south: .path, west: .forest), biome: .naturalGrass),
        cell(2, 1, CellEdges(north: .forest, east: .forest, south: .open, west: .path), biome: .darkGreenForest)
    ]

    static let forestPass = [
        cell(0, 0, CellEdges(north: .path, east: .blocked, south: .open, west: .blocked), biome: .darkGreenForest),
        cell(0, 1, CellEdges(north: .path, east: .blocked, south: .path, west: .blocked), biome: .darkGreenForest),
        cell(0, 2, CellEdges(north: .blocked, east: .path, south: .path, west: .blocked), biome: .naturalGrass),
        cell(1, 2, CellEdges(north: .blocked, east: .open, south: .blocked, west: .path), biome: .darkGreenForest)
    ]

    static let hill = [
        cell(-1, 0, CellEdges(north: .cliff, east: .open, south: .open, west: .cliff), biome: .hillSoil),
        cell(0, 0, CellEdges(north: .cliff, east: .path, south: .open, west: .open), biome: .hillSoil),
        cell(1, 0, CellEdges(north: .cliff, east: .cliff, south: .open, west: .path), biome: .hillSoil),
        cell(0, 1, CellEdges(north: .open, east: .cliff, south: .path, west: .cliff), biome: .hillSoil)
    ]

    static let outerWilderness = [
        cell(0, 0, .open, biome: .rocksalt),
        cell(1, 0, .open, biome: .rocksalt),
        cell(2, 0, CellEdges(north: .open, east: .path, south: .open, west: .open), biome: .rocksalt),
        cell(3, 0, CellEdges(north: .open, east: .open, south: .open, west: .path), biome: .rocksalt)
    ]

    private static func cell(_ x: Int, _ y: Int, _ edges: CellEdges, biome: BiomeType) -> WorldCellDefinition {
        WorldCellDefinition(localPosition: GridPosition(x: x, y: y), edges: edges, biome: biome)
    }

    private static func cell(_ x: Int, _ y: Int, _ edges: CellEdges, biomeEdges: CellBiomeEdges) -> WorldCellDefinition {
        WorldCellDefinition(localPosition: GridPosition(x: x, y: y), edges: edges, biomeEdges: biomeEdges)
    }
}

private enum PieceIDs {
    static let village = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
    static let forestWest = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2))
    static let forestEast = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3))
    static let forestPass = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4))
    static let hill = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5))
    static let outerWilderness = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6))
}
