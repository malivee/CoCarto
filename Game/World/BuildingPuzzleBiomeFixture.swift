import Foundation

enum BuildingPuzzlePieceID: String, CaseIterable, Sendable {
    case z1 = "Z1"
    case z2 = "Z2"
    case l1 = "L1"
    case t1 = "T1"
    case s1 = "S1"
}

enum BuildingPuzzleCellID: String, CaseIterable, Sendable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case h = "H"
    case i = "I"
    case j = "J"
    case k = "K"
    case l = "L"
    case m = "M"
    case n = "N"
    case o = "O"
    case p = "P"
    case q = "Q"
    case r = "R"
    case s = "S"
    case t = "T"
}

struct BuildingPuzzleKnownArrangement: Equatable, Sendable {
    struct Placement: Equatable, Sendable {
        let pieceID: BuildingPuzzlePieceID
        let position: GridPosition
        let rotation: GridRotation
    }

    let placements: [Placement]
    let rectangle: GlobalMicroRectangle
}

enum BuildingPuzzleBiomeFixture {
    static let expectedMicroCellCount = 720

    static let knownWell = BuildingPuzzleKnownArrangement(
        placements: [],
        rectangle: GlobalMicroRectangle(origin: GlobalMicroPosition(x: -30, y: 0), width: 3, height: 3)
    )

    static let knownSixBySix = BuildingPuzzleKnownArrangement(
        placements: [
            .init(pieceID: .l1, position: GridPosition(x: -1, y: 0), rotation: .degrees270),
            .init(pieceID: .s1, position: GridPosition(x: 0, y: 3), rotation: .degrees270)
        ],
        rectangle: GlobalMicroRectangle(origin: GlobalMicroPosition(x: 0, y: 6), width: 6, height: 6)
    )

    static let knownSixByNine = BuildingPuzzleKnownArrangement(
        placements: [
            .init(pieceID: .l1, position: GridPosition(x: -1, y: 0), rotation: .degrees270),
            .init(pieceID: .t1, position: GridPosition(x: 0, y: 2), rotation: .degrees180)
        ],
        rectangle: GlobalMicroRectangle(origin: GlobalMicroPosition(x: 0, y: 6), width: 6, height: 9)
    )

    static let knownBarn = BuildingPuzzleKnownArrangement(
        placements: [
            .init(pieceID: .z1, position: GridPosition(x: 4, y: 2), rotation: .degrees180),
            .init(pieceID: .z2, position: GridPosition(x: -2, y: -1), rotation: .degrees0),
            .init(pieceID: .l1, position: GridPosition(x: 1, y: 1), rotation: .degrees90),
            .init(pieceID: .t1, position: GridPosition(x: 1, y: -1), rotation: .degrees0),
            .init(pieceID: .s1, position: GridPosition(x: 4, y: 0), rotation: .degrees180)
        ],
        rectangle: GlobalMicroRectangle(origin: GlobalMicroPosition(x: 6, y: -6), width: 15, height: 9)
    )

    static let pieceUUIDs: [BuildingPuzzlePieceID: UUID] = [
        .z1: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1)),
        .z2: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2)),
        .l1: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3)),
        .t1: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 4)),
        .s1: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5))
    ]

    static let cellIDsByPiece: [BuildingPuzzlePieceID: [BuildingPuzzleCellID]] = [
        .z1: [.a, .b, .c, .d],
        .z2: [.e, .f, .g, .h],
        .l1: [.i, .j, .k, .l],
        .t1: [.m, .n, .o, .p],
        .s1: [.q, .r, .s, .t]
    ]

    static let biomeEdgesByCellID: [BuildingPuzzleCellID: CellBiomeEdges] = [
        .a: mixed(north: .naturalGrass, east: .villageSoil, south: .villageSoil, west: .naturalGrass),
        .b: mixed(north: .naturalGrass, east: .villageSoil, south: .villageSoil, west: .naturalGrass),
        .c: mixed(north: .villageSoil, east: .villageSoil, south: .naturalGrass, west: .naturalGrass),
        .d: mixed(north: .villageSoil, east: .naturalGrass, south: .naturalGrass, west: .villageSoil),
        .e: mixed(north: .villageSoil, east: .villageSoil, south: .villageSoil, west: .naturalGrass),
        .f: mixed(north: .naturalGrass, east: .villageSoil, south: .villageSoil, west: .villageSoil),
        .g: mixed(north: .villageSoil, east: .naturalGrass, south: .naturalGrass, west: .villageSoil),
        .h: mixed(north: .naturalGrass, east: .villageSoil, south: .villageSoil, west: .naturalGrass),
        .i: mixed(north: .villageSoil, east: .villageSoil, south: .villageSoil, west: .naturalGrass),
        .j: mixed(north: .villageSoil, east: .villageSoil, south: .naturalGrass, west: .villageSoil),
        .k: mixed(north: .naturalGrass, east: .villageSoil, south: .villageSoil, west: .villageSoil),
        .l: mixed(north: .villageSoil, east: .naturalGrass, south: .villageSoil, west: .villageSoil),
        .m: mixed(north: .villageSoil, east: .naturalGrass, south: .naturalGrass, west: .villageSoil),
        .n: mixed(north: .villageSoil, east: .naturalGrass, south: .naturalGrass, west: .villageSoil),
        .o: mixed(north: .naturalGrass, east: .villageSoil, south: .villageSoil, west: .naturalGrass),
        .p: mixed(north: .naturalGrass, east: .villageSoil, south: .villageSoil, west: .naturalGrass),
        .q: mixed(north: .villageSoil, east: .villageSoil, south: .naturalGrass, west: .naturalGrass),
        .r: mixed(north: .naturalGrass, east: .naturalGrass, south: .villageSoil, west: .villageSoil),
        .s: mixed(north: .villageSoil, east: .naturalGrass, south: .villageSoil, west: .villageSoil),
        .t: mixed(north: .naturalGrass, east: .villageSoil, south: .villageSoil, west: .naturalGrass)
    ]

    static func grid(for cellID: BuildingPuzzleCellID) -> MicroBiomeGrid {
        guard let edges = biomeEdgesByCellID[cellID] else {
            preconditionFailure("Missing biome edges for cell \(cellID.rawValue).")
        }
        return MicroBiomeGridGenerator().generate(from: edges)
    }

    static func biomeEdges(for cellID: BuildingPuzzleCellID) -> CellBiomeEdges {
        guard let edges = biomeEdgesByCellID[cellID] else {
            preconditionFailure("Missing biome edges for cell \(cellID.rawValue).")
        }
        return edges
    }

    static func debugDescription(pieceID: BuildingPuzzlePieceID, cellID: BuildingPuzzleCellID) -> String {
        let edges = biomeEdges(for: cellID)
        return "\(pieceID.rawValue) / Cell \(cellID.rawValue)\n\nBiome Edges: \(edges.debugDescription())\n\nGenerated Microgrid:\n\(grid(for: cellID).debugDescription())"
    }

    static func apply(_ arrangement: BuildingPuzzleKnownArrangement, to worldState: inout WorldState) {
        for placement in arrangement.placements {
            guard let id = pieceUUIDs[placement.pieceID] else {
                continue
            }
            _ = worldState.movePiece(id: id, to: placement.position, rotation: placement.rotation)
        }
    }

    static func pieceID(for role: PieceRole) -> BuildingPuzzlePieceID? {
        switch role {
        case .z1:
            return .z1
        case .z2:
            return .z2
        case .l1:
            return .l1
        case .t1:
            return .t1
        case .s1:
            return .s1
        case .village, .forestWest, .forestEast, .forestPass, .hill, .outerWilderness:
            return nil
        }
    }
}

extension WorldState {
    static let buildingPuzzleBiomePrototype = WorldState(pieces: [
        BuildingPuzzleBiomeFixture.makePiece(
            pieceID: .z1,
            type: .i,
            role: .z1,
            position: GridPosition(x: -5, y: 0),
            rotation: .degrees0
        ),
        BuildingPuzzleBiomeFixture.makePiece(
            pieceID: .z2,
            type: .i,
            role: .z2,
            position: GridPosition(x: 2, y: -4),
            rotation: .degrees0
        ),
        BuildingPuzzleBiomeFixture.makePiece(
            pieceID: .l1,
            type: .l,
            role: .l1,
            position: GridPosition(x: 5, y: 1),
            rotation: .degrees0
        )
    ], landmarks: [])
}

private extension BuildingPuzzleBiomeFixture {
    static func mixed(
        north: BiomeType,
        east: BiomeType,
        south: BiomeType,
        west: BiomeType
    ) -> CellBiomeEdges {
        CellBiomeEdges(north: north, east: east, south: south, west: west)
    }

    static func makePiece(
        pieceID: BuildingPuzzlePieceID,
        type: TetrominoType,
        role: PieceRole,
        position: GridPosition,
        rotation: GridRotation
    ) -> WorldPiece {
        guard let uuid = pieceUUIDs[pieceID], let cellIDs = cellIDsByPiece[pieceID] else {
            preconditionFailure("Missing fixture data for piece \(pieceID.rawValue).")
        }
        let definitions = zip(type.baseCells, cellIDs).map { localPosition, cellID in
            WorldCellDefinition(
                id: GridID(cellID.rawValue),
                localPosition: localPosition,
                edges: .open,
                biomeEdges: biomeEdges(for: cellID)
            )
        }
        return WorldPiece(
            id: uuid,
            type: type,
            role: role,
            gridPosition: position,
            rotation: rotation,
            isMovable: true,
            cellDefinitions: definitions
        )
    }
}
