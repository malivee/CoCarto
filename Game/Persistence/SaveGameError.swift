enum SaveGameError: Error, Equatable, Sendable {
    case fileNotFound
    case encodingFailed
    case decodingFailed
    case unsupportedVersion(Int)
    case writeFailed
    case deleteFailed
}
