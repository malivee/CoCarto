import Foundation

final class SaveGameService {
    private let fileManager: FileManager
    private let fileName: String
    private let directoryURL: URL

    init(
        fileManager: FileManager = .default,
        fileName: String = "prototype-save.json",
        directoryURL: URL? = nil
    ) throws {
        self.fileManager = fileManager
        self.fileName = fileName

        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let applicationSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.directoryURL = applicationSupport.appendingPathComponent("very-disco-3", isDirectory: true)
        }
    }

    var saveURL: URL {
        directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }

    func saveExists() -> Bool {
        fileManager.fileExists(atPath: saveURL.path)
    }

    func save(_ data: GameSaveData) throws {
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let encoded = try makeEncoder().encode(data)
            try encoded.write(to: saveURL, options: [.atomic])
        } catch is EncodingError {
            throw SaveGameError.encodingFailed
        } catch {
            throw SaveGameError.writeFailed
        }
    }

    func load() throws -> GameSaveData {
        guard saveExists() else {
            throw SaveGameError.fileNotFound
        }

        do {
            let rawData = try Data(contentsOf: saveURL)
            let versionEnvelope = try JSONDecoder().decode(SaveVersionEnvelope.self, from: rawData)
            guard versionEnvelope.version <= SaveVersion.current else {
                throw SaveGameError.unsupportedVersion(versionEnvelope.version)
            }
            return try JSONDecoder().decode(GameSaveData.self, from: rawData)
        } catch let error as SaveGameError {
            throw error
        } catch is DecodingError {
            throw SaveGameError.decodingFailed
        } catch {
            throw SaveGameError.decodingFailed
        }
    }

    func deleteSave() throws {
        guard saveExists() else {
            return
        }

        do {
            try fileManager.removeItem(at: saveURL)
        } catch {
            throw SaveGameError.deleteFailed
        }
    }

    func encodedJSONString(for data: GameSaveData) throws -> String {
        do {
            let encoded = try makeEncoder().encode(data)
            return String(decoding: encoded, as: UTF8.self)
        } catch {
            throw SaveGameError.encodingFailed
        }
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        #if DEBUG
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        #endif
        return encoder
    }
}

private struct SaveVersionEnvelope: Decodable {
    let version: Int
}
