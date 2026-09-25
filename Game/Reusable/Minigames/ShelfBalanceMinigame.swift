// Penjelasan file: BuMaraShelfMinigameView.swift
// Minigame SwiftUI untuk menolong Bu Mara: Mengangkat rak kayu tembikar di pekarangan luar rumah.
// Menggunakan Gyroscope (CoreMotion) untuk menyeimbangkan rak, lalu QTE (DBD Slider) untuk
// menyelipkan Batu Bata Merah tepat waktu agar rak berdiri kokoh dan napak tanah.

import SwiftUI
import CoreMotion
import Combine // Ditambahkan untuk fix error autoconnect()

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Game States & Models

public enum ShelfGameState: Equatable {
    case lifting        // Tahap 1: Miringkan HP (Gyro) untuk seimbangkan rak
    case hammering      // Tahap 2: Ketuk palu 2x untuk mengunci rapat pasak
    case won            // Menang: Rak berdiri kokoh di pekarangan
    case failed         // Gagal: Pot jatuh pecah atau meleset
}

public enum ShelfFailReason {
    case dropped
    case liftedTooHigh
    case missedQTE
}

public struct PotDebris: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var rotation: Double
    public var scale: CGFloat
}

// MARK: - Main Minigame View

public struct BuMaraShelfMinigameView: View {
    public var onComplete: ((Bool) -> Void)?
    public var onDismiss: (() -> Void)?
    
    public init(onComplete: ((Bool) -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }
    
    // Game States
    @State private var gameState: ShelfGameState = .lifting
    @State private var failReason: ShelfFailReason = .dropped
    
    // Physics: 14 derajat kemiringan awal ambles ke tanah
    @State private var shelfAngle: Double = 14.0
    
    // Gyroscope Motion Manager
    private let motionManager = CMMotionManager()
    @State private var isGyroActive: Bool = false
    
    // DBD Slider States (Quick Time Event)
    @State private var dbdProgress: Double = 0.0
    @State private var dbdDirection: Double = 1.0
    private let dbdSpeed: Double = 1.15
    private let targetStart: Double = 0.65
    private let targetEnd: Double = 0.82
    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    // Wedge & Hammer States
    @State private var isWedgePlaced: Bool = false
    @State private var hammerTaps: Int = 0
    @State private var hammerWiggle: CGFloat = 0.0
    
    // Visual FX & Pot Physics
    @State private var potSlideOffset: CGFloat = 8.0
    @State private var potOpacity: Double = 1.0
    @State private var shatteredPieces: [PotDebris] = []
    @State private var plantRustle: Double = 0.0
    
    // Screen Feedback & Ambient
    @State private var screenShake: CGFloat = 0.0
    @State private var warningFlash: Double = 0.0
    @State private var successFlash: Double = 0.0
    @State private var lastHapticAngle: Int = 14
    @State private var gardenBreeze: Double = 0.0
    
    // Limits
    private let balancedRange: ClosedRange<Double> = -2.5...2.5
    private let failAngleUp: Double = -13.0
    
    // Dimensions
    private let shelfWidth: CGFloat = 330
    private let legWidth: CGFloat = 24
    private let legHeight: CGFloat = 110
    private let plankHeight: CGFloat = 20
    private let potsHeight: CGFloat = 55
    
    public var body: some View {
        GeometryReader { proxy in
            let screenSize = CGSize(
                width: proxy.size.width > 50 ? proxy.size.width : 844,
                height: proxy.size.height > 50 ? proxy.size.height : 390
            )
            
            let groundY = screenSize.height * 0.75
            let pivotX = max(screenSize.width * 0.18, (screenSize.width - shelfWidth) * 0.35)
            let pivotY = groundY
            let rightFootTarget = CGPoint(x: pivotX + shelfWidth - legWidth / 2, y: groundY)
            let initialWedgePos = CGPoint(x: min(rightFootTarget.x + 85, screenSize.width - 65), y: groundY + 14)
            
            ZStack {
                // 1. Background Luar Rumah Bu Mara
                OutdoorCottageGardenBackground(groundY: groundY, breeze: gardenBreeze)
                    .ignoresSafeArea()
                
                SunlightRayOverlay()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // FX Screen Flash
                Color.red.opacity(warningFlash).ignoresSafeArea().allowsHitTesting(false)
                Color.green.opacity(successFlash).ignoresSafeArea().allowsHitTesting(false)
                
                // 2. Teks Status Minimalis (Di Atas)
                CinematicHeader(gameState: gameState, isBalanced: balancedRange.contains(shelfAngle))
                    .position(x: screenSize.width / 2, y: 40)
                
                // 3. Ground Elements
                MudSinkholePit(isWedgePlaced: isWedgePlaced)
                    .position(x: rightFootTarget.x, y: groundY + 16)
                
                LeftFootStonePaver()
                    .position(x: pivotX + legWidth / 2, y: groundY + 6)
                
                Ellipse()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 44, height: 10)
                    .position(x: pivotX + legWidth / 2, y: groundY + 8)
                
                // 4. DBD Slider (Hanya muncul saat seimbang sebelum diganjal)
                if balancedRange.contains(shelfAngle) && !isWedgePlaced && gameState == .lifting {
                    DBDTrackView(progress: dbdProgress, targetStart: targetStart, targetEnd: targetEnd)
                        .position(x: rightFootTarget.x, y: groundY - 30)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // 5. PENGGANJAL (Otomatis geser saat QTE Berhasil)
                let wedgeCurrentX = isWedgePlaced ? rightFootTarget.x : initialWedgePos.x
                let wedgeCurrentY = isWedgePlaced ? (groundY + 14) : initialWedgePos.y
                
                InteractivePengganjalView(
                    isPlaced: isWedgePlaced,
                    hammerTaps: hammerTaps,
                    onTapToHammer: handleHammerTap
                )
                .offset(x: hammerWiggle)
                .position(x: wedgeCurrentX, y: wedgeCurrentY)
                .allowsHitTesting(isWedgePlaced && hammerTaps < 2) // Hanya bisa ditap saat fase hammering
                
                // 6. RAK KAYU & TEMBIKAR UTUH
                SinglePieceShelfFurniture(
                    shelfWidth: shelfWidth,
                    legWidth: legWidth,
                    legHeight: legHeight,
                    plankHeight: plankHeight,
                    potsHeight: potsHeight,
                    isWedgePlaced: isWedgePlaced,
                    potSlideOffset: potSlideOffset,
                    potOpacity: potOpacity,
                    plantRustle: plantRustle,
                    onTapPot: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            plantRustle = Double.random(in: -10...10)
                        }
                        #if canImport(UIKit)
                        HapticsService.shared.playImpact(style: .light)
                        #endif
                    }
                )
                .rotationEffect(
                    .degrees(shelfAngle),
                    anchor: UnitPoint(x: (legWidth / 2) / shelfWidth, y: 1.0)
                )
                .position(x: pivotX + shelfWidth / 2 - legWidth / 2, y: pivotY - (legHeight + plankHeight + potsHeight) / 2)
                
                // 7. Tombol Palu Cepat (Fase Hammering)
                if isWedgePlaced && hammerTaps < 2 {
                    Button(action: handleHammerTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "hammer.fill").font(.system(size: 14, weight: .bold))
                            Text("KETUK PALU MENGUNCI RAPAT (\(hammerTaps)/2)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(colors: [Color(red: 1.0, green: 0.82, blue: 0.35), Color(red: 0.95, green: 0.62, blue: 0.15)], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.6), radius: 8, y: 3)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 1.5))
                    }
                    .position(x: screenSize.width * 0.5, y: screenSize.height - 40)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 8. Pecahan Pot jika Gagal
                ForEach(shatteredPieces) { piece in
                    PotShardShape()
                        .fill(Color(red: 0.68, green: 0.38, blue: 0.20))
                        .frame(width: 18 * piece.scale, height: 18 * piece.scale)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }
                
                // 9. Modals
                if gameState == .failed {
                    FailurePopupModal(reason: failReason, onRetry: resetGame)
                }
                if gameState == .won {
                    VictoryPopupModal(onContinue: {
                        onComplete?(true)
                        onDismiss?()
                    })
                }
                
                // 10. Close Button
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .position(x: screenSize.width - 40, y: 40)
                }
            }
            .offset(x: screenShake)
            .contentShape(Rectangle()) // Make the whole screen tappable
            .onTapGesture {
                // Precision Tap untuk DBD
                if balancedRange.contains(shelfAngle) && !isWedgePlaced && gameState == .lifting {
                    evaluateDBDTap()
                }
            }
            .onAppear {
                startGyroscope()
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                    gardenBreeze = 4.0
                }
            }
            .onDisappear {
                stopGyroscope()
            }
            .onReceive(timer) { _ in
                // Update DBD Slider progress
                guard gameState == .lifting, !isWedgePlaced, balancedRange.contains(shelfAngle) else { return }
                dbdProgress += (0.02 * dbdSpeed) * dbdDirection
                if dbdProgress >= 1.0 { dbdProgress = 1.0; dbdDirection = -1.0 }
                if dbdProgress <= 0.0 { dbdProgress = 0.0; dbdDirection = 1.0 }
            }
        }
    }
    
    // MARK: - CoreMotion (Gyroscope)
    
    private func startGyroscope() {
        guard motionManager.isDeviceMotionAvailable else {
            isGyroActive = false
            return
        }
        isGyroActive = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion = motion, gameState == .lifting else { return }
            
            // Evaluasi kemiringan HP (Roll/Pitch dinamis)
            let roll = motion.gravity.x
            let pitch = motion.gravity.y
            let dominantTilt = abs(roll) > abs(pitch) ? -roll : pitch
            
            // Hitung target sudut rak dari kemiringan gyro
            let targetAngle = 14.0 + (Double(dominantTilt) * 25.0)
            let clamped = max(-14.0, min(18.0, targetAngle))
            
            withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.8)) {
                shelfAngle = clamped
            }
            
            evaluateAnglePhysics(shelfAngle)
        }
    }
    
    private func stopGyroscope() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    // MARK: - Handlers & Physics
    
    private func evaluateAnglePhysics(_ angle: Double) {
        let intAngle = Int(angle)
        if intAngle != lastHapticAngle {
            lastHapticAngle = intAngle
            #if canImport(UIKit)
            if balancedRange.contains(angle) {
                HapticsService.shared.playImpact(style: .rigid)
            } else {
                HapticsService.shared.playImpact(style: .light)
            }
            #endif
        }
        
        // Geseran pot di atas papan
        if angle > 4.0 {
            potSlideOffset = CGFloat((angle - 4.0) * 1.5)
        } else if angle < -3.5 {
            potSlideOffset = CGFloat((angle + 3.5) * 1.8)
        } else {
            potSlideOffset = 0.0
        }
        
        // Terangkat melampaui batas
        if angle <= failAngleUp {
            handleFail(reason: .liftedTooHigh)
        }
    }
    
    private func evaluateDBDTap() {
        if dbdProgress >= targetStart && dbdProgress <= targetEnd {
            // SUCCESS
            withAnimation(.easeOut(duration: 0.15)) { successFlash = 0.4 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.25)) { successFlash = 0.0 }
            }
            snapWedgeInPlace()
        } else {
            // MISS
            handleFail(reason: .missedQTE)
        }
    }
    
    private func snapWedgeInPlace() {
        isWedgePlaced = true
        gameState = .hammering
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            shelfAngle = 0.0
            potSlideOffset = 0.0
        }
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.success)
        #endif
        triggerShake(intensity: 4.0)
    }
    
    private func handleHammerTap() {
        guard isWedgePlaced, hammerTaps < 2 else { return }
        hammerTaps += 1
        
        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: hammerTaps == 2 ? .heavy : .medium)
        #endif
        triggerShake(intensity: hammerTaps == 2 ? 6.0 : 3.0)
        
        withAnimation(.default) { hammerWiggle = 3.5 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.default) { hammerWiggle = -3.5 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) { hammerWiggle = 0 }
        }
        
        if hammerTaps >= 2 {
            #if canImport(UIKit)
            HapticsService.shared.playNotification(.success)
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                gameState = .won
            }
        }
    }
    
    private func handleFail(reason: ShelfFailReason) {
        guard gameState != .won, gameState != .failed else { return }
        gameState = .failed
        failReason = reason
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.error)
        #endif
        triggerShake(intensity: 12.0)
        
        withAnimation(.easeOut(duration: 0.1)) { warningFlash = 0.5 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.3)) { warningFlash = 0.0 }
        }
        
        triggerShatter(at: CGPoint(x: 480, y: 260))
        
        if reason == .missedQTE {
            // Anjlok balik
            withAnimation(.easeIn(duration: 0.2)) {
                shelfAngle = 14.0
            }
        }
    }
    
    private func triggerShatter(at point: CGPoint) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            potOpacity = 0.0
            #if canImport(UIKit)
            HapticsService.shared.playImpact(style: .heavy)
            #endif
            
            shatteredPieces.removeAll()
            for _ in 0..<16 {
                let p = PotDebris(
                    position: CGPoint(
                        x: point.x + CGFloat.random(in: -15...15),
                        y: point.y + CGFloat.random(in: -15...15)
                    ),
                    rotation: Double.random(in: 0...360),
                    scale: CGFloat.random(in: 0.7...1.3)
                )
                shatteredPieces.append(p)
            }
            
            withAnimation(.easeOut(duration: 0.45)) {
                for i in shatteredPieces.indices {
                    shatteredPieces[i].position.x += CGFloat.random(in: -70...70)
                    shatteredPieces[i].position.y += CGFloat.random(in: -35...35)
                    shatteredPieces[i].rotation += Double.random(in: -180...180)
                }
            }
        }
    }
    
    private func resetGame() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            gameState = .lifting
            shelfAngle = 14.0
            isWedgePlaced = false
            hammerTaps = 0
            dbdProgress = 0.0
            potSlideOffset = 8.0
            potOpacity = 1.0
            shatteredPieces.removeAll()
            warningFlash = 0.0
        }
    }
    
    private func triggerShake(intensity: CGFloat) {
        withAnimation(.default) { screenShake = intensity }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.default) { screenShake = -intensity }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) { screenShake = 0 }
        }
    }
}

// MARK: - Minimal UI Components

public struct CinematicHeader: View {
    public let gameState: ShelfGameState
    public let isBalanced: Bool
    
    public var body: some View {
        Text(statusText)
            .font(.system(size: 16, weight: .heavy))
            .italic()
            .foregroundColor(statusColor)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 2)
            .animation(.easeInOut, value: gameState)
    }
    
    private var statusText: String {
        switch gameState {
        case .lifting: return isBalanced ? "SEIMBANG! TAP LAYAR UNTUK MENGGANJAL!" : "MIRINGKAN HP UNTUK SEIMBANGKAN RAK!"
        case .hammering: return "BATA MASUK! KETUK PALU!"
        case .won: return "RAK KOKOH!"
        case .failed: return "TERGULING!"
        }
    }
    
    private var statusColor: Color {
        switch gameState {
        case .lifting: return isBalanced ? Color(red: 0.4, green: 0.95, blue: 0.5) : Color(red: 1.0, green: 0.85, blue: 0.6)
        case .won: return Color(red: 0.4, green: 0.95, blue: 0.5)
        case .failed: return .red
        default: return Color(red: 1.0, green: 0.85, blue: 0.6)
        }
    }
}

public struct DBDTrackView: View {
    public let progress: Double
    public let targetStart: Double
    public let targetEnd: Double
    public let width: CGFloat = 240
    public let height: CGFloat = 18
    
    public var body: some View {
        ZStack(alignment: .leading) {
            // Track Base
            Capsule()
                .fill(Color.black.opacity(0.85))
                .frame(width: width, height: height)
                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
            
            // Green Zone
            let zoneW = width * (targetEnd - targetStart)
            let zoneX = width * targetStart
            Capsule()
                .fill(Color.green.opacity(0.8))
                .frame(width: zoneW, height: height)
                .offset(x: zoneX)
            
            // Cursor
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.orange)
                .frame(width: 14, height: height + 10)
                .shadow(color: .black, radius: 2)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white, lineWidth: 1.5))
                .offset(x: width * progress - 7)
        }
    }
}

// MARK: - Outdoor Cottage Garden Background (Luar Rumah & Napak Tanah)

public struct OutdoorCottageGardenBackground: View {
    public let groundY: CGFloat
    public let breeze: Double
    
    public var body: some View {
        ZStack {
            // 1. Langit Pekarangan Luar Rumah (Outdoor Morning Sky)
            LinearGradient(
                colors: [
                    Color(red: 0.40, green: 0.65, blue: 0.85),
                    Color(red: 0.68, green: 0.82, blue: 0.92),
                    Color(red: 0.90, green: 0.82, blue: 0.70)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // 2. Siluet Dinding Luar Pondok Bu Mara di Kiri (Exterior Wall & Eaves)
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                
                // Dinding luar kayu/batu pondok di tepi kiri
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: w * 0.28, y: 0))
                    p.addLine(to: CGPoint(x: w * 0.24, y: groundY))
                    p.addLine(to: CGPoint(x: 0, y: groundY))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.32, green: 0.22, blue: 0.16), Color(red: 0.24, green: 0.16, blue: 0.11)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Papan Lisplang Atap Luar
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 35))
                    p.addLine(to: CGPoint(x: w * 0.30, y: 25))
                    p.addLine(to: CGPoint(x: w * 0.29, y: 48))
                    p.addLine(to: CGPoint(x: 0, y: 55))
                    p.closeSubpath()
                }
                .fill(Color(red: 0.20, green: 0.12, blue: 0.08))
                
                // Tanaman Merambat di Dinding Luar (Ivy / Climber)
                HStack(spacing: 18) {
                    OutdoorHangingPlantView(color: Color(red: 0.28, green: 0.58, blue: 0.25))
                        .rotationEffect(.degrees(breeze), anchor: .top)
                    OutdoorHangingPlantView(color: Color(red: 0.35, green: 0.65, blue: 0.30))
                        .rotationEffect(.degrees(-breeze * 0.7), anchor: .top)
                    Spacer()
                }
                .padding(.leading, 30)
                .padding(.top, 45)
                
                // Pagar Kayu Pekarangan di Belakang Kanan
                Path { p in
                    let fenceStart = w * 0.42
                    let fenceEnd = w
                    p.move(to: CGPoint(x: fenceStart, y: groundY - 30))
                    p.addLine(to: CGPoint(x: fenceEnd, y: groundY - 30))
                    p.move(to: CGPoint(x: fenceStart, y: groundY - 15))
                    p.addLine(to: CGPoint(x: fenceEnd, y: groundY - 15))
                }
                .stroke(Color(red: 0.45, green: 0.32, blue: 0.20).opacity(0.75), lineWidth: 3)
                
                // 3. TANAH PEKARANGAN PADAT & RUMPUT (Napak Tanah Line)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: groundY))
                    p.addLine(to: CGPoint(x: w, y: groundY))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.16, blue: 0.11), Color(red: 0.14, green: 0.09, blue: 0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Lapisan Rumput Hijau Pekarangan Tepat di Garis Tanah
                Path { p in
                    p.move(to: CGPoint(x: 0, y: groundY))
                    p.addLine(to: CGPoint(x: w, y: groundY))
                }
                .stroke(Color(red: 0.32, green: 0.52, blue: 0.22), lineWidth: 5)
                
                // Rumput-rumput Liar & Batu Kerikil
                Path { p in
                    for i in 0..<18 {
                        let x = CGFloat(i) * (w / 18) + 8
                        p.move(to: CGPoint(x: x, y: groundY))
                        p.addLine(to: CGPoint(x: x - 4, y: groundY - 8))
                        p.move(to: CGPoint(x: x + 2, y: groundY))
                        p.addLine(to: CGPoint(x: x + 6, y: groundY - 11))
                    }
                }
                .stroke(Color(red: 0.40, green: 0.65, blue: 0.26).opacity(0.8), lineWidth: 1.8)
            }
        }
    }
}

public struct OutdoorHangingPlantView: View {
    public let color: Color
    
    public var body: some View {
        VStack(spacing: 2) {
            Rectangle().fill(Color(red: 0.3, green: 0.2, blue: 0.1)).frame(width: 2, height: 14)
            Capsule().fill(color).frame(width: 14, height: 38)
        }
    }
}

public struct SunlightRayOverlay: View {
    public var body: some View {
        Canvas { context, size in
            guard size.width > 10 && size.height > 10 else { return }
            var beam = Path()
            beam.move(to: CGPoint(x: -40, y: -40))
            beam.addLine(to: CGPoint(x: size.width * 0.45, y: -40))
            beam.addLine(to: CGPoint(x: size.width * 0.85, y: size.height))
            beam.addLine(to: CGPoint(x: size.width * 0.20, y: size.height))
            beam.closeSubpath()
            context.fill(
                beam,
                with: .linearGradient(
                    Gradient(colors: [Color.yellow.opacity(0.18), Color.clear]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width * 0.6, y: size.height)
                )
            )
        }
    }
}

// MARK: - Single Piece Shelf Furniture (Napak Tanah)

public struct SinglePieceShelfFurniture: View {
    public let shelfWidth: CGFloat
    public let legWidth: CGFloat
    public let legHeight: CGFloat
    public let plankHeight: CGFloat
    public let potsHeight: CGFloat
    public let isWedgePlaced: Bool
    public let potSlideOffset: CGFloat
    public let potOpacity: Double
    public let plantRustle: Double
    public var onTapPot: (() -> Void)?
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Tiga Pot Bu Mara di Atas Papan
            HStack(spacing: 36) {
                TerracottaHerbalPot(plantRustle: plantRustle, onTap: onTapPot)
                GlazedCeramicJar(onTap: onTapPot)
                FolkEarthenwareBowl(onTap: onTapPot)
            }
            .frame(width: shelfWidth, height: potsHeight, alignment: .bottom)
            .offset(x: potSlideOffset)
            .opacity(potOpacity)
            
            // 2. Papan Meja Kayu Tebal
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.58, green: 0.38, blue: 0.22), Color(red: 0.40, green: 0.24, blue: 0.14)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: shelfWidth + 20, height: plankHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(red: 0.72, green: 0.52, blue: 0.32).opacity(0.4), lineWidth: 1)
                    )
                
                // Serat Kayu Meja
                Path { p in
                    p.move(to: CGPoint(x: 10, y: 7))
                    p.addQuadCurve(to: CGPoint(x: shelfWidth + 10, y: 7), control: CGPoint(x: shelfWidth * 0.5, y: 5))
                }
                .stroke(Color.black.opacity(0.35), lineWidth: 1.5)
                
                // Plat Besi Sudut Meja
                HStack {
                    CornerIronBracket()
                    Spacer()
                    CornerIronBracket()
                }
                .frame(width: shelfWidth + 12)
                .padding(.horizontal, 4)
            }
            .frame(width: shelfWidth, height: plankHeight)
            
            // 3. Kaki-kaki dan Rangka Penyangga (Napak Tanah)
            ZStack(alignment: .topLeading) {
                // Palang Penyangga Horizontal
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.46, green: 0.30, blue: 0.17), Color(red: 0.32, green: 0.20, blue: 0.11)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: shelfWidth - 40, height: 12)
                    .position(x: shelfWidth / 2, y: legHeight * 0.48)
                
                // Skur Penguat Sudut (Diagonal Braces)
                Path { p in
                    p.move(to: CGPoint(x: legWidth, y: 32))
                    p.addLine(to: CGPoint(x: legWidth + 30, y: 0))
                    p.move(to: CGPoint(x: shelfWidth - legWidth, y: 32))
                    p.addLine(to: CGPoint(x: shelfWidth - legWidth - 30, y: 0))
                }
                .stroke(Color(red: 0.42, green: 0.26, blue: 0.15), lineWidth: 8)
                
                // Kaki Kiri
                TimberLeg(width: legWidth, height: legHeight)
                    .position(x: legWidth / 2, y: legHeight / 2)
                
                // Kaki Kanan
                TimberLeg(width: legWidth, height: legHeight)
                    .position(x: shelfWidth - legWidth / 2, y: legHeight / 2)
            }
            .frame(width: shelfWidth, height: legHeight)
        }
        .frame(width: shelfWidth, height: potsHeight + plankHeight + legHeight)
    }
}

public struct TimberLeg: View {
    public let width: CGFloat
    public let height: CGFloat
    
    public var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.44, green: 0.28, blue: 0.16), Color(red: 0.28, green: 0.16, blue: 0.09)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: height)
            
            Circle()
                .fill(Color(white: 0.2))
                .frame(width: 5, height: 5)
                .offset(y: 8)
        }
    }
}

public struct CornerIronBracket: View {
    public var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(white: 0.25))
            .frame(width: 20, height: 8)
            .overlay(
                HStack(spacing: 8) {
                    Circle().fill(Color.black).frame(width: 2.5, height: 2.5)
                    Circle().fill(Color.black).frame(width: 2.5, height: 2.5)
                }
            )
    }
}

// MARK: - Artisan Pots & Shapes

public struct TerracottaHerbalPot: View {
    public let plantRustle: Double
    public var onTap: (() -> Void)?
    
    public var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .bottom) {
                ZStack {
                    HerbLeaf(color: Color(red: 0.32, green: 0.62, blue: 0.26))
                        .frame(width: 14, height: 22)
                        .rotationEffect(.degrees(-30 + plantRustle))
                        .offset(x: -12, y: -38)
                    
                    HerbLeaf(color: Color(red: 0.40, green: 0.72, blue: 0.32))
                        .frame(width: 14, height: 22)
                        .rotationEffect(.degrees(25 + plantRustle))
                        .offset(x: 12, y: -40)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().fill(Color.yellow).frame(width: 3.5, height: 3.5))
                        .offset(x: 1, y: -43)
                }
                
                TerracottaShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.76, green: 0.42, blue: 0.22), Color(red: 0.52, green: 0.25, blue: 0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 50)
                    .overlay(
                        Path { p in
                            p.move(to: CGPoint(x: 8, y: 22))
                            p.addLine(to: CGPoint(x: 50, y: 22))
                        }
                        .stroke(Color(red: 0.92, green: 0.72, blue: 0.52).opacity(0.6), lineWidth: 1.5)
                    )
                
                Ellipse()
                    .fill(Color(red: 0.35, green: 0.16, blue: 0.09))
                    .frame(width: 38, height: 8)
                    .offset(y: -48)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct GlazedCeramicJar: View {
    public var onTap: (() -> Void)?
    
    public var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .bottom) {
                GlazedPotShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.68, blue: 0.62), Color(red: 0.12, green: 0.44, blue: 0.38)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 44)
                    .overlay(
                        Path { p in
                            p.move(to: CGPoint(x: 12, y: 12))
                            p.addQuadCurve(to: CGPoint(x: 16, y: 34), control: CGPoint(x: 8, y: 22))
                        }
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                
                Rectangle()
                    .fill(Color(red: 0.82, green: 0.68, blue: 0.45))
                    .frame(width: 28, height: 3.5)
                    .offset(y: -38)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct FolkEarthenwareBowl: View {
    public var onTap: (() -> Void)?
    
    public var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .bottom) {
                ClayBowlMiniShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.84, green: 0.60, blue: 0.32), Color(red: 0.60, green: 0.38, blue: 0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 26)
                
                Image(systemName: "circle.dotted")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.3))
                    .offset(y: -8)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct HerbLeaf: View {
    public let color: Color
    public var body: some View {
        Ellipse().fill(color)
    }
}

public struct TerracottaShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 12, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX - 5, y: rect.maxY * 0.8))
        p.addQuadCurve(to: CGPoint(x: rect.minX + 10, y: rect.minY), control: CGPoint(x: rect.minX + 2, y: rect.midY * 0.4))
        p.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX - 2, y: rect.midY * 0.4))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 12, y: rect.maxY), control: CGPoint(x: rect.maxX + 5, y: rect.maxY * 0.8))
        p.closeSubpath()
        return p
    }
}

public struct GlazedPotShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 8, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX - 4, y: rect.maxY * 0.75))
        p.addQuadCurve(to: CGPoint(x: rect.minX + 8, y: rect.minY), control: CGPoint(x: rect.minX + 2, y: rect.midY * 0.4))
        p.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX - 2, y: rect.midY * 0.4))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 8, y: rect.maxY), control: CGPoint(x: rect.maxX + 4, y: rect.maxY * 0.75))
        p.closeSubpath()
        return p
    }
}

public struct ClayBowlMiniShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 6, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY), control: CGPoint(x: rect.minX - 3, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 6, y: rect.maxY), control: CGPoint(x: rect.maxX + 3, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

public struct PotShardShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 3))
        p.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 2))
        p.closeSubpath()
        return p
    }
}

// MARK: - Modals & Overlays

public struct InteractivePengganjalView: View {
    public let isPlaced: Bool
    public let hammerTaps: Int
    public var onTapToHammer: (() -> Void)?
    
    public var body: some View {
        Button(action: {
            if isPlaced && hammerTaps < 2 {
                onTapToHammer?()
            }
        }) {
            VStack(spacing: 4) {
                // Batu Bata Merah Utama
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.82, green: 0.32, blue: 0.20), Color(red: 0.56, green: 0.18, blue: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black.opacity(0.35), lineWidth: 1)
                        )
                    
                    HStack(spacing: 4) {
                        Circle().fill(Color.black.opacity(0.2)).frame(width: 6, height: 6)
                        Text("BATA GANJAL")
                            .font(.system(size: 6.5, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                        Circle().fill(Color.black.opacity(0.2)).frame(width: 6, height: 6)
                    }
                }
                
                // Pasak Kayu di Bawah Bata
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.65, green: 0.44, blue: 0.22), Color(red: 0.42, green: 0.26, blue: 0.12)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 12)
                    
                    Text("PASAK KAYU")
                        .font(.system(size: 6, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .scaleEffect(isPlaced && hammerTaps == 2 ? 1.0 : (isPlaced ? 1.05 : 1.0))
            .shadow(color: .black.opacity(0.4), radius: 3, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isPlaced ? (hammerTaps >= 2 ? Color.green : Color.yellow) : Color.orange, lineWidth: 1.5)
                    .padding(-4)
            )
            .opacity(isPlaced ? 1.0 : 0.0) // Sembunyikan jika belum di tempat (otomatis masuk saat QTE berhasil)
        }
        .buttonStyle(.plain)
    }
}

public struct MudSinkholePit: View {
    public let isWedgePlaced: Bool
    
    public var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.11, green: 0.08, blue: 0.05))
                .frame(width: 95, height: 32)
            
            Ellipse()
                .fill(Color(red: 0.16, green: 0.12, blue: 0.08).opacity(0.85))
                .frame(width: 68, height: 18)
                .offset(x: -2, y: 2)
            
            if !isWedgePlaced {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .background(Color.green.opacity(0.12))
                    .frame(width: 58, height: 36)
                    .offset(y: -4)
                
                Text("PASANG GANJAL")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(.green)
                    .offset(y: -28)
            }
        }
    }
}

public struct LeftFootStonePaver: View {
    public var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.42), Color(white: 0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 38, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1)
            )
    }
}

public struct VictoryPopupModal: View {
    public let onContinue: () -> Void
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.green)
                
                Text("RAK BERDIRI KOKOH!")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Terima kasih Arthur! Berkat ganjalan batu bata dan pasak kayu darimu, rak tembikar Bu Mara di pekarangan berdiri kokoh napak tanah!")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text("LANJUTKAN")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(14)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color(red: 0.14, green: 0.18, blue: 0.13))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.6), lineWidth: 1.5))
            .frame(maxWidth: 440)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

public struct FailurePopupModal: View {
    public let reason: ShelfFailReason
    public let onRetry: () -> Void
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.orange)
                
                Text(reason == .liftedTooHigh ? "DIANGKAT TERLALU TINGGI!" : "POT BU MARA JATUH PECAH!")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(reason == .liftedTooHigh
                     ? "Rak terangkat melampaui batas sehingga pot meluncur jatuh ke kiri."
                     : (reason == .missedQTE ? "Batu bata gagal diselipkan dan rak kembali anjlok keras!" : "Rak terlepas sebelum penopang terpasang, menyebabkan benturan keras!"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("COBA LAGI")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 10)
                    .background(Color(red: 1.0, green: 0.85, blue: 0.45))
                    .cornerRadius(14)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color(red: 0.18, green: 0.13, blue: 0.10))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.5), lineWidth: 1.5))
            .frame(maxWidth: 420)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Compatibility Typealiases

public typealias ShelfBalanceMinigame = BuMaraShelfMinigameView
public typealias ShelfBalanceMinigameView = BuMaraShelfMinigameView

// MARK: - Previews

#if canImport(SwiftUI) && DEBUG
#Preview("Bu Mara Shelf Minigame", traits: .landscapeLeft) {
    BuMaraShelfMinigameView()
}
#endif
