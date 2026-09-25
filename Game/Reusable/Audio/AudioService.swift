// Penjelasan file: AudioService.swift
// Layanan terpusat untuk memutar Background Music (BGM) dan Sound Effect (SFX)
// Menggunakan NSDataAsset dan AVAudioPlayer dari kumpulan SFX di xcassets.

import AVFoundation
import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class AudioService: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    public static let shared = AudioService()

    private var bgmPlayer: AVAudioPlayer?
    public private(set) var currentBgmTrack: String?
    private var activeSfxPlayers: [AVAudioPlayer] = []
    private var lastPlayTimes: [String: TimeInterval] = [:]
    private let queue = DispatchQueue(label: "com.cocarto.audioService")

    public var bgmVolume: Float = 0.65
    public var sfxVolume: Float = 1.0

    private override init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        #if canImport(UIKit)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioService] Failed to configure AVAudioSession: \(error)")
        }
        #endif
    }

    private func loadAudioData(named name: String) -> Data? {
        #if canImport(UIKit)
        if let asset = NSDataAsset(name: name) {
            return asset.data
        }
        if let asset = NSDataAsset(name: "SFX/\(name)") {
            return asset.data
        }
        #endif

        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            return try? Data(contentsOf: url)
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "SFX") {
            return try? Data(contentsOf: url)
        }
        return nil
    }

    // MARK: - Background Music (BGM)

    /// Memutar BGM berdasarkan nama asset (misal: "Vilage" atau "RockSalt").
    /// Jika track sudah berjalan, panggilan ini tidak akan mengulang dari awal.
    /// Jika berganti track, track sebelumnya akan dimatikan dan digantikan track baru.
    public func playBGM(_ trackName: String, loop: Bool = true, fadeDuration: TimeInterval = 0.4) {
        if currentBgmTrack == trackName, let player = bgmPlayer, player.isPlaying {
            return
        }

        guard let data = loadAudioData(named: trackName) else {
            print("[AudioService] Warning: Audio data not found for BGM '\(trackName)'")
            return
        }

        do {
            let newPlayer = try AVAudioPlayer(data: data, fileTypeHint: "mp3")
            newPlayer.numberOfLoops = loop ? -1 : 0
            newPlayer.prepareToPlay()

            let previousPlayer = self.bgmPlayer
            self.bgmPlayer = newPlayer
            self.currentBgmTrack = trackName

            if let previous = previousPlayer, previous.isPlaying {
                // Matikan suara sebelumnya secara halus dan mainkan yang baru
                previous.setVolume(0, fadeDuration: fadeDuration)
                DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                    previous.stop()
                }
                newPlayer.volume = 0
                newPlayer.play()
                newPlayer.setVolume(bgmVolume, fadeDuration: fadeDuration)
            } else {
                newPlayer.volume = bgmVolume
                newPlayer.play()
            }
        } catch {
            print("[AudioService] Failed to start BGM '\(trackName)': \(error)")
        }
    }

    /// Menghentikan BGM yang sedang berjalan
    public func stopBGM(fadeDuration: TimeInterval = 0.3) {
        guard let player = bgmPlayer else { return }
        currentBgmTrack = nil

        if fadeDuration > 0 {
            player.setVolume(0, fadeDuration: fadeDuration)
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak self] in
                if self?.currentBgmTrack == nil {
                    player.stop()
                    self?.bgmPlayer = nil
                }
            }
        } else {
            player.stop()
            bgmPlayer = nil
        }
    }

    // MARK: - Sound Effects (SFX)

    /// Memutar sound effect satu kali.
    /// - Parameters:
    ///   - name: Nama dataset atau file SFX (misal: "WellWaterPull", "PaperMap", "TampahTray", "WaterSorting", "RockSalt")
    ///   - volumeMultiplier: Pengali volume relatif (0.0 - 1.0)
    ///   - throttleInterval: Minimal interval (detik) sebelum SFX dengan nama yang sama boleh dibunyikan kembali
    public func playSFX(_ name: String, volumeMultiplier: Float = 1.0, throttleInterval: TimeInterval = 0) {
        let now = CACurrentMediaTime()
        if throttleInterval > 0 {
            if let lastTime = lastPlayTimes[name], now - lastTime < throttleInterval {
                return
            }
        }
        lastPlayTimes[name] = now

        guard let data = loadAudioData(named: name) else {
            print("[AudioService] Warning: Audio data not found for SFX '\(name)'")
            return
        }

        do {
            let player = try AVAudioPlayer(data: data, fileTypeHint: "mp3")
            player.volume = sfxVolume * max(0, min(1, volumeMultiplier))
            player.delegate = self
            player.prepareToPlay()
            player.play()

            queue.sync {
                activeSfxPlayers.append(player)
            }
        } catch {
            print("[AudioService] Failed to play SFX '\(name)': \(error)")
        }
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        queue.sync {
            activeSfxPlayers.removeAll { $0 === player }
        }
    }
}
