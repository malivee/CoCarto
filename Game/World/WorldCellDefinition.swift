import Foundation

struct WorldCellDefinition: Codable, Hashable, Sendable {
    let id: GridID
    let localPosition: GridPosition
    let edges: CellEdges
    let biomeEdges: CellBiomeEdges
    private let customMicroBiomeGrid: MicroBiomeGrid?

    var microBiomeGrid: MicroBiomeGrid {
        customMicroBiomeGrid ?? MicroBiomeGridGenerator().generate(from: biomeEdges)
    }

    init(
        id: GridID? = nil,
        localPosition: GridPosition,
        edges: CellEdges,
        biomeEdges: CellBiomeEdges = .uniform(.naturalGrass),
        microBiomeGrid: MicroBiomeGrid? = nil
    ) {
        self.id = id ?? GridID("\(localPosition.x),\(localPosition.y)")
        self.localPosition = localPosition
        self.edges = edges
        self.biomeEdges = biomeEdges
        self.customMicroBiomeGrid = microBiomeGrid
    }

    init(
        id: GridID? = nil,
        localPosition: GridPosition,
        edges: CellEdges,
        biome: BiomeType
    ) {
        self.init(id: id, localPosition: localPosition, edges: edges, biomeEdges: .uniform(biome))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case localPosition
        case edges
        case biomeEdges
        case microBiomeGrid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let localPosition = try container.decode(GridPosition.self, forKey: .localPosition)
        self.id = try container.decodeIfPresent(GridID.self, forKey: .id) ?? GridID("\(localPosition.x),\(localPosition.y)")
        self.localPosition = localPosition
        self.edges = try container.decode(CellEdges.self, forKey: .edges)
        if let biomeEdges = try container.decodeIfPresent(CellBiomeEdges.self, forKey: .biomeEdges) {
            self.biomeEdges = biomeEdges
            self.customMicroBiomeGrid = try container.decodeIfPresent(MicroBiomeGrid.self, forKey: .microBiomeGrid)
        } else if let oldGrid = try container.decodeIfPresent(MicroBiomeGrid.self, forKey: .microBiomeGrid),
                  let biome = oldGrid.cells().compactMap(\.biome).first {
            self.biomeEdges = .uniform(biome)
            self.customMicroBiomeGrid = oldGrid
        } else {
            self.biomeEdges = .uniform(.naturalGrass)
            self.customMicroBiomeGrid = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(localPosition, forKey: .localPosition)
        try container.encode(edges, forKey: .edges)
        try container.encode(biomeEdges, forKey: .biomeEdges)
        try container.encodeIfPresent(customMicroBiomeGrid, forKey: .microBiomeGrid)
    }
}

struct ResolvedWorldCell: Hashable, Sendable {
    let pieceID: UUID
    let gridID: GridID
    let sourceLocalPosition: GridPosition
    let localPosition: GridPosition
    let globalPosition: GridPosition
    let edges: CellEdges
    let localBiomeEdges: CellBiomeEdges
    let biomeEdges: CellBiomeEdges
    let sourceMicroBiomeGrid: MicroBiomeGrid
    let microBiomeGrid: MicroBiomeGrid
}
