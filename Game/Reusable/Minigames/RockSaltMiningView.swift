import SwiftUI

// MARK: - Models

public struct SaltDustParticle: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var velocity: CGPoint
    public var scale: CGFloat = CGFloat.random(in: 0.6...1.6)
    public var opacity: Double = 1.0
    public var color: Color = .white
}

public struct CrackSegment: Identifiable {
    public let id = UUID()
    public var start: CGPoint
    public var end: CGPoint
    public var width: CGFloat
}

public struct RockImpactMark: Identifiable {
    public let id = UUID()
    public var center: CGPoint
    public var segments: [CrackSegment] = []
}

public struct CrystalDebris: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var rotation: Double
    public var scale: CGFloat
}

// MARK: - Main View

public struct RockSaltCarvingView: View {
    public var onComplete: (() -> Void)?
    public var onDismiss: (() -> Void)?
    
    public init(onComplete: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }

    // Status Permainan
    @State private var mountainHits: Int = 0
    private let maxHits: Int = 7 // Diubah ke 7 pukulan
    @State private var isShrunk: Bool = false // Menyusut di hit ke-5
    @State private var isMountainDestroyed: Bool = false // Hancur lebur di hit ke-7
    
    // Dialog Naratif
    @State private var dialogMessage: String = "Arthur, ketuk bongkahan garam ini untuk memecahkannya!"
    @State private var isShowingDialog: Bool = true
    
    // Efek Visual
    @State private var rockMarks: [RockImpactMark] = []
    @State private var particles: [SaltDustParticle] = []
    @State private var shatteredPieces: [CrystalDebris] = []
    @State private var pickaxePosition: CGPoint = CGPoint(x: 200, y: 300)
    @State private var pickaxeRotation: Double = -20
    @State private var screenShake: CGFloat = 0.0
    @State private var saltGlowPulse: CGFloat = 1.0
    
    // Feedback Haptic Native
    #if canImport(UIKit)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let successNotify = UINotificationFeedbackGenerator()
    #endif
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background Gelap Gua Tambang
                RadialGradient(
                    gradient: Gradient(colors: [Color(red: 0.18, green: 0.14, blue: 0.12), Color(red: 0.06, green: 0.04, blue: 0.03)]),
                    center: .center,
                    startRadius: 50,
                    endRadius: proxy.size.height * 0.8
                )
                .ignoresSafeArea()
                
                // Vignette Shadow
                Rectangle()
                    .strokeBorder(Color.black.opacity(0.6), lineWidth: 40)
                    .blur(radius: 20)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    topQuestPanel
                        .zIndex(2)
                    
                    // Area Utama Permainan
                    ZStack {
                        // Cahaya Pendar di belakang garam
                        Circle()
                            .fill(Color(red: 0.95, green: 0.98, blue: 1.0).opacity(isMountainDestroyed ? 0.0 : (isShrunk ? 0.15 : 0.25)))
                            .frame(width: 260, height: 260)
                            .blur(radius: 40)
                            .scaleEffect(saltGlowPulse)
                            .offset(y: isShrunk ? 120 : 40)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isShrunk)
                        
                        // Gambar Bongkahan Garam Utama
                        if !isMountainDestroyed {
                            Image("rocksalt")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 320)
                                // Menyusut menjadi gundukan kecil setelah 5 hits
                                .scaleEffect(isShrunk ? 0.45 : 1.0)
                                .offset(y: isShrunk ? 140 : 40)
                                .animation(.spring(response: 0.6, dampingFraction: 0.55), value: isShrunk)
                                .transition(.opacity)
                        }
                        
                        // Retakan pada bongkahan
                        if !isMountainDestroyed {
                            Canvas { context, _ in
                                for mark in rockMarks {
                                    for seg in mark.segments {
                                        var path = Path()
                                        path.move(to: seg.start)
                                        path.addLine(to: seg.end)
                                        
                                        // Bayangan retakan untuk kedalaman
                                        context.stroke(
                                            path,
                                            with: .color(Color.black.opacity(0.4)),
                                            style: StrokeStyle(lineWidth: seg.width + 2, lineCap: .round)
                                        )
                                        // Retakan inti putih/kristal
                                        context.stroke(
                                            path,
                                            with: .color(Color.white.opacity(0.95)),
                                            style: StrokeStyle(lineWidth: seg.width, lineCap: .round)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Partikel Debu Garam
                        ForEach(particles) { pt in
                            Circle()
                                .fill(pt.color.opacity(pt.opacity))
                                .frame(width: 6 * pt.scale, height: 6 * pt.scale)
                                .shadow(color: pt.color.opacity(0.8), radius: 3)
                                .position(pt.position)
                        }
                        
                        // Pecahan Kristal Garam (Shattered Debris) saat hancur total
                        ForEach(shatteredPieces) { piece in
                            CrystalShardShape()
                                .fill(LinearGradient(colors: [Color.white, Color(red: 0.85, green: 0.95, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 24 * piece.scale, height: 24 * piece.scale)
                                .rotationEffect(.degrees(piece.rotation))
                                .position(piece.position)
                                .shadow(color: Color.white.opacity(0.5), radius: 4)
                        }
                        
                        // Beliung Tambang (Pickaxe)
                        if !isMountainDestroyed {
                            PickaxeToolView()
                                .rotationEffect(.degrees(pickaxeRotation), anchor: .bottomLeading)
                                .position(pickaxePosition)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle()) // Area interaktif penuh
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                handlePickaxeStrike(at: value.location)
                            }
                    )
                }
                
                // Dialog Naratif Anneth di Bawah
                if isShowingDialog {
                    VStack {
                        Spacer()
                        dialogueBubbleView
                    }
                    .zIndex(5)
                }
                
                // Modal Kemenangan
                if isMountainDestroyed {
                    victoryModal
                        .zIndex(20)
                }
            }
            .offset(x: screenShake)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        isShowingDialog = false
                    }
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    saltGlowPulse = 1.15
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var topQuestPanel: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ROCK SALT")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.98, green: 0.95, blue: 0.90))
                    .shadow(color: Color.black.opacity(0.8), radius: 1, x: 1, y: 1)
                
                Text("Kumpulkan pecahan garam")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Counter Hits (Maksimal 7)
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.6, green: 0.9, blue: 1.0))
                    Text("\(mountainHits)/\(maxHits)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(red: 0.12, green: 0.08, blue: 0.05).opacity(0.8))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.5, green: 0.8, blue: 0.9), lineWidth: 1.5)
                )
                
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.12, green: 0.08, blue: 0.05).opacity(0.8))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color(red: 0.5, green: 0.8, blue: 0.9), lineWidth: 1.5))
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.10, blue: 0.06).opacity(0.98), Color(red: 0.08, green: 0.05, blue: 0.03).opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(Rectangle().fill(Color(red: 0.5, green: 0.8, blue: 0.9).opacity(0.4)).frame(height: 1.5), alignment: .bottom)
        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
    }
    
    private var dialogueBubbleView: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ANNETH")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.98, green: 0.85, blue: 0.48))
                
                Text(dialogMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(red: 0.10, green: 0.08, blue: 0.09).opacity(0.95))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 0.85, green: 0.65, blue: 0.32).opacity(0.9), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 12, y: 6)
        .padding(.horizontal, 24)
        .padding(.bottom, 36)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var victoryModal: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 0.6, green: 0.9, blue: 1.0).opacity(0.4), .clear], center: .center, startRadius: 10, endRadius: 70))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 56))
                        .foregroundColor(Color.white)
                        .shadow(color: Color.cyan.opacity(0.8), radius: 20)
                }
                
                Text("GARAM TERKUMPUL!")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(Color.white)
                
                Text("Kristal rock salt murni telah dipecahkan dan siap dibawa untuk persediaan dapur desa.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.85, green: 0.90, blue: 0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Button(action: {
                    onComplete?()
                    onDismiss?()
                }) {
                    Text("SELESAI")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.05, green: 0.1, blue: 0.2))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.8, green: 0.95, blue: 1.0), Color(red: 0.5, green: 0.85, blue: 1.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.cyan.opacity(0.5), radius: 12, y: 5)
                }
                .padding(.top, 12)
            }
            .padding(32)
            .background(Color(red: 0.12, green: 0.14, blue: 0.16))
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.cyan.opacity(0.6), lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.9), radius: 35)
            .padding(.horizontal, 32)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }
    
    // MARK: - Game Logic
    
    private func handlePickaxeStrike(at tapLocation: CGPoint) {
        guard !isMountainDestroyed else { return }
        
        pickaxePosition = CGPoint(x: tapLocation.x + 40, y: tapLocation.y - 50)
        pickaxeRotation = -50
        
        withAnimation(.easeIn(duration: 0.08)) {
            pickaxeRotation = 15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            executeStrikeAt(tapLocation)
            
            withAnimation(.easeOut(duration: 0.15)) {
                pickaxeRotation = -20
            }
        }
    }
    
    private func executeStrikeAt(_ point: CGPoint) {
        #if canImport(UIKit)
        heavyImpact.impactOccurred(intensity: 0.8)
        #endif
        
        triggerShake(intensity: 5.0)
        spawnSparks(at: point, count: 18)
        
        var newMark = RockImpactMark(center: point)
        addCrackBranches(to: &newMark.segments, center: point, intensity: mountainHits + 1)
        rockMarks.append(newMark)
        
        mountainHits += 1
        
        // Fase 1: Menyusut di Pukulan ke-5
        if mountainHits == 5 {
            triggerShrink(at: point)
            return
        }
        
        // Fase 2: Hancur Total di Pukulan ke-7
        if mountainHits >= maxHits {
            triggerMountainCollapse(at: point)
            return
        }
        
        // Update Dialog Biasa
        withAnimation(.easeInOut(duration: 0.3)) {
            if mountainHits == 2 {
                dialogMessage = "Bagus! Retakannya mulai menyebar!"
                isShowingDialog = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { isShowingDialog = false }
                }
            } else if mountainHits == 4 {
                dialogMessage = "Satu pukulan kuat lagi untuk memecahkannya!"
                isShowingDialog = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { isShowingDialog = false }
                }
            } else if mountainHits == 6 {
                dialogMessage = "Gundukannya hampir hancur! Pukul sekali lagi!"
                isShowingDialog = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { isShowingDialog = false }
                }
            }
        }
    }
    
    private func triggerShrink(at point: CGPoint) {
        #if canImport(UIKit)
        heavyImpact.impactOccurred(intensity: 1.0)
        #endif
        triggerShake(intensity: 12.0)
        spawnSparks(at: point, count: 40)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            isShrunk = true
        }
        
        // Hapus retakan sebelumnya agar gundukan kecil terlihat bersih
        withAnimation {
            rockMarks.removeAll()
            dialogMessage = "Bongkahan terpecah! Sekarang hancurkan gundukannya untuk dibawa!"
            isShowingDialog = true
        }
    }
    
    private func triggerMountainCollapse(at point: CGPoint) {
        #if canImport(UIKit)
        heavyImpact.impactOccurred(intensity: 1.0)
        #endif
        triggerShake(intensity: 18.0)
        spawnSparks(at: CGPoint(x: 200, y: 450), count: 60)
        
        // Ledakan pecahan kristal (Shattered Debris)
        for _ in 0..<20 {
            let piece = CrystalDebris(
                position: CGPoint(x: point.x + CGFloat.random(in: -30...30), y: point.y + CGFloat.random(in: -20...20)),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.6...1.5)
            )
            shatteredPieces.append(piece)
        }
        
        withAnimation(.easeOut(duration: 0.5)) {
            for i in shatteredPieces.indices {
                shatteredPieces[i].position.x += CGFloat.random(in: -100...100)
                shatteredPieces[i].position.y += CGFloat.random(in: -60...100)
                shatteredPieces[i].rotation += Double.random(in: -180...180)
            }
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            dialogMessage = "Sempurna! Garam siap dikumpulkan."
            isShowingDialog = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                isMountainDestroyed = true
            }
            #if canImport(UIKit)
            successNotify.notificationOccurred(.success)
            #endif
        }
    }
    
    private func addCrackBranches(to segments: inout [CrackSegment], center: CGPoint, intensity: Int) {
        // Skala retakan dikecilkan jika sudah menyusut
        let multiplier: CGFloat = isShrunk ? 0.5 : 1.0
        let branchCount = Int.random(in: 5...8)
        let baseRadius: CGFloat = CGFloat(intensity) * 15.0 * multiplier
        
        for _ in 0..<branchCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let length = CGFloat.random(in: 20...baseRadius + 25) * multiplier
            
            let mid = CGPoint(
                x: center.x + cos(angle) * (length * 0.5) + CGFloat.random(in: -8...8),
                y: center.y + sin(angle) * (length * 0.5) + CGFloat.random(in: -8...8)
            )
            let end = CGPoint(
                x: center.x + cos(angle) * length,
                y: center.y + sin(angle) * length
            )
            
            segments.append(CrackSegment(start: center, end: mid, width: CGFloat.random(in: 3.0...5.0) * multiplier))
            segments.append(CrackSegment(start: mid, end: end, width: CGFloat.random(in: 1.5...2.5) * multiplier))
        }
    }
    
    private func spawnSparks(at origin: CGPoint, count: Int) {
        let colors: [Color] = [.white, Color(red: 0.95, green: 0.98, blue: 1.0), Color(red: 0.85, green: 0.95, blue: 1.0)]
        for _ in 0..<count {
            let p = SaltDustParticle(
                position: origin,
                velocity: CGPoint(x: CGFloat.random(in: -80...80), y: CGFloat.random(in: -90...70)),
                scale: CGFloat.random(in: 0.8...3.0),
                color: colors.randomElement() ?? .white
            )
            particles.append(p)
        }
        
        withAnimation(.easeOut(duration: 0.6)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            particles.removeAll()
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

// MARK: - Subviews & Shapes

public struct PickaxeToolView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.45, green: 0.28, blue: 0.16), Color(red: 0.32, green: 0.19, blue: 0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 14, height: 140)
                .overlay(Capsule().stroke(Color.black.opacity(0.6), lineWidth: 1.5))
                .rotationEffect(.degrees(32))
                .offset(x: 32, y: 40)
            
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color.gray, Color.black], startPoint: .top, endPoint: .bottom))
                .frame(width: 18, height: 18)
                .offset(y: -2)
            
            PickaxeHeadShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.7, green: 0.7, blue: 0.75), Color(red: 0.3, green: 0.3, blue: 0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 55)
                .shadow(color: .black.opacity(0.6), radius: 6, x: 2, y: 5)
            
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
                .shadow(color: .white, radius: 6)
                .offset(x: -55, y: 20)
        }
        .frame(width: 150, height: 150)
    }
}

public struct PickaxeHeadShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX
        
        p.move(to: CGPoint(x: midX, y: rect.minY + 6))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY * 0.85), control: CGPoint(x: rect.width * 0.2, y: rect.minY + 2))
        p.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY * 0.95))
        p.addQuadCurve(to: CGPoint(x: midX - 8, y: rect.midY + 6), control: CGPoint(x: rect.width * 0.25, y: rect.maxY * 0.45))
        p.addLine(to: CGPoint(x: midX + 8, y: rect.midY + 6))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 4, y: rect.maxY * 0.7), control: CGPoint(x: rect.width * 0.75, y: rect.maxY * 0.4))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.5))
        p.addQuadCurve(to: CGPoint(x: midX, y: rect.minY + 6), control: CGPoint(x: rect.width * 0.8, y: rect.minY + 4))
        
        p.closeSubpath()
        return p
    }
}

// Shape untuk pecahan/debris kristal (tidak lagi cokelat tanah, melainkan bentuk kristal)
public struct CrystalShardShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - 4))
        p.addLine(to: CGPoint(x: rect.midX + 4, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY + 4))
        p.closeSubpath()
        return p
    }
}

public typealias RockSaltMiningView = RockSaltCarvingView

#Preview {
    RockSaltCarvingView()
}
