// Penjelasan file: GameScene+Audio.swift
// Mengelola transisi Background Music (BGM) berdasarkan posisi pemain dan area/biome yang sedang dijelajahi.
// Memutar lagu "Vilage" di area desa dan bertransisi ke lagu "RockSalt" saat berada di area garam batu.

import CoreGraphics
import SpriteKit

extension GameScene {
    func updateAreaAudio() {
        guard let playerNode else {
            AudioService.shared.playBGM("Vilage")
            return
        }

        let isRockSalt = isPositionInRockSaltArea(playerNode.position)
        let trackName = isRockSalt ? "RockSalt" : "Vilage"
        AudioService.shared.playBGM(trackName)
    }

    func isPositionInRockSaltArea(_ position: CGPoint) -> Bool {
        let cellPosition = mapper.gridPosition(containing: position)
        guard let pieceID = worldState.occupancy.pieceID(at: cellPosition),
              let piece = worldState.piece(id: pieceID) else {
            return false
        }

        guard let cell = piece.resolvedCells().first(where: { $0.globalPosition == cellPosition }) else {
            return false
        }

        let cellCenter = mapper.worldPosition(for: cellPosition)
        let localX = position.x - (cellCenter.x - mapper.halfCellSize)
        let localY = position.y - (cellCenter.y - mapper.halfCellSize)
        let microDimension = mapper.cellSize / CGFloat(MicroBiomeGrid.dimension)
        let microX = max(0, min(MicroBiomeGrid.dimension - 1, Int(floor(localX / microDimension))))
        let microY = max(0, min(MicroBiomeGrid.dimension - 1, Int(floor(localY / microDimension))))
        let microPos = MicroGridPosition(x: microX, y: microY)

        if let biome = cell.microBiomeGrid.biome(at: microPos) {
            return biome == .rocksalt
        }
        if let split = cell.microBiomeGrid.split(at: microPos) {
            return split.primaryBiome == .rocksalt || split.secondaryBiome == .rocksalt
        }
        return cell.biomeEdges.north == .rocksalt ||
               cell.biomeEdges.east == .rocksalt ||
               cell.biomeEdges.south == .rocksalt ||
               cell.biomeEdges.west == .rocksalt
    }
}
