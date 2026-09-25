import Foundation

struct MicroGridPosition: Hashable, Codable, Sendable {
    let x: Int
    let y: Int

    init(x: Int, y: Int) {
        precondition(Self.isValid(x: x, y: y), "MicroGridPosition must be inside 0..<\(MicroBiomeGrid.dimension).")
        self.x = x
        self.y = y
    }

    init(validatingX x: Int, y: Int) throws {
        guard Self.isValid(x: x, y: y) else {
            throw MicroBiomeGridError.invalidPosition(x: x, y: y)
        }
        self.x = x
        self.y = y
    }

    static func isValid(x: Int, y: Int) -> Bool {
        (0..<MicroBiomeGrid.dimension).contains(x) && (0..<MicroBiomeGrid.dimension).contains(y)
    }

    private enum CodingKeys: String, CodingKey {
        case x
        case y
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Int.self, forKey: .x)
        let y = try container.decode(Int.self, forKey: .y)
        try self.init(validatingX: x, y: y)
    }
}
