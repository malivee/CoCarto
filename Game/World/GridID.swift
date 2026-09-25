import Foundation

struct GridID: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    var description: String {
        rawValue
    }
}
