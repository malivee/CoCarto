import SwiftUI
import CoreHaptics

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
    private let maxHits: Int = 5
    @State private var isMountainDestroyed: Bool = false
    
    // Dialog Naratif (Seragam dengan ItemSortingMinigame / Anneth)
    @State private var dialogMessage: String = "Arthur, ketuk untuk memahat batu!"
    @State private var isShowingDialog: Bool = true
    
    // Efek Visual
    @State private var rockMarks: [RockImpactMark] = []
    @State private var particles: [SaltDustParticle] = []
    @State private var pickaxePosition: CGPoint = CGPoint(x: 200, y: 300)
    @State private var pickaxeRotation: Double = -20
    @State private var screenShake: CGFloat = 0.0
    
    // Haptics
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let successNotify = UINotificationFeedbackGenerator()
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background gelap hangat desa & vignette
                Color(red: 0.06, green: 0.04, blue: 0.03).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topQuestPanel
                        .zIndex(2)
                    
                    // Area Gunung
                    ZStack {
                        if !isMountainDestroyed {
                            // Gambar Gunung Garam
                            Image("image_efdcbd")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()
                                .transition(.scale.combined(with: .opacity))
                            
                            // Retakan pada gunung
                            Canvas { context, _ in
                                for mark in rockMarks {
                                    for seg in mark.segments {
                                        var path = Path()
                                        path.move(to: seg.start)
                                        path.addLine(to: seg.end)
                                        context.stroke(
                                            path,
                                            with: .color(Color.white.opacity(0.85)),
                                            style: StrokeStyle(lineWidth: seg.width, lineCap: .round)
                                        )
                                        // Bayangan retakan untuk kedalaman
                                        context.stroke(
                                            path,
                                            with: .color(Color.black.opacity(0.6)),
                                            style: StrokeStyle(lineWidth: seg.width + 1, lineCap: .round)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Partikel Debu
                        ForEach(particles) { pt in
                            Circle()
                                .fill(pt.color.opacity(pt.opacity))
                                .frame(width: 6 * pt.scale, height: 6 * pt.scale)
                                .position(pt.position)
                        }
                        
                        // Beliung Tambang (Pickaxe)
                        PickaxeToolView()
                            .rotationEffect(.degrees(pickaxeRotation), anchor: .bottomLeading)
                            .position(pickaxePosition)
                            .animation(.easeOut(duration: 0.12), value: pickaxeRotation)
                            .allowsHitTesting(false)
                            .opacity(isMountainDestroyed ? 0 : 1)
                        
                        // Vignette Bayangan di Sekeliling Layar
                        Rectangle()
                            .strokeBorder(Color.black.opacity(0.55), lineWidth: 35)
                            .allowsHitTesting(false)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                handlePickaxeStrike(at: value.location)
                            }
                    )
                }
                
                // Dialog Naratif Anneth di Bawah Layar
                if !isMountainDestroyed {
                    dialogueBubbleView
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowingDialog = false
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var topQuestPanel: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("ROCK SALT")
                    .font(.custom("AvenirNext-Bold", size: 14))
                    .foregroundColor(Color(red: 0.95, green: 0.88, blue: 0.72))
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Counter pill kayu & emas
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.80, blue: 0.35))
                        Text("\(mountainHits)/\(maxHits)")
                            .font(.custom("AvenirNext-Bold", size: 13))
                            .foregroundColor(Color(red: 0.95, green: 0.88, blue: 0.72))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.16, green: 0.11, blue: 0.07))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.72, green: 0.55, blue: 0.30), lineWidth: 1.5)
                    )
                    
                    if let onDismiss = onDismiss {
                        Button(action: onDismiss) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.16, green: 0.11, blue: 0.07))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color(red: 0.65, green: 0.50, blue: 0.30), lineWidth: 1.5))
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(red: 0.95, green: 0.88, blue: 0.72))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.08, blue: 0.05).opacity(0.96),
                        Color(red: 0.08, green: 0.05, blue: 0.03).opacity(0.90)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Garis pembatas emas artistik
            Rectangle()
                .fill(Color(red: 0.78, green: 0.64, blue: 0.38).opacity(0.4))
                .frame(height: 1.0)
        }
    }
    
    private var dialogueBubbleView: some View {
        VStack {
            Spacer()
            if isShowingDialog {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ANNETH")
                            .font(.custom("AvenirNext-Bold", size: 11))
                            .foregroundColor(Color(red: 0.96, green: 0.83, blue: 0.48))
                        
                        Text(dialogMessage)
                            .font(.custom("AvenirNext-Medium", size: 12))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.08, green: 0.07, blue: 0.09).opacity(0.95))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.85, green: 0.65, blue: 0.32).opacity(0.8), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 8, y: 4)
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
    }
    
    private var victoryModal: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            
            VStack(spacing: 18) {
                // Ikon Kristal Garam Berpendar
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.95, green: 0.80, blue: 0.40).opacity(0.35), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 55
                            )
                        )
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "sparkle")
                        .font(.system(size: 54))
                        .foregroundColor(Color(red: 0.98, green: 0.85, blue: 0.45))
                        .shadow(color: Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.8), radius: 16)
                }
                
                Text("TAMBANG BERHASIL!")
                    .font(.custom("AvenirNext-Heavy", size: 24))
                    .foregroundColor(Color(red: 0.95, green: 0.88, blue: 0.72))
                
                Text("Anda berhasil menambang bongkahan rock salt murni dari pegunungan untuk perbekalan desa.")
                    .font(.custom("AvenirNext-Medium", size: 14))
                    .foregroundColor(Color(red: 0.80, green: 0.72, blue: 0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Button(action: {
                    onComplete?()
                    onDismiss?()
                }) {
                    Text("SELESAI")
                        .font(.custom("AvenirNext-Bold", size: 16))
                        .foregroundColor(Color(red: 0.14, green: 0.09, blue: 0.05))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.78, blue: 0.35),
                                    Color(red: 0.82, green: 0.60, blue: 0.22)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.4), radius: 10, y: 4)
                }
                .padding(.top, 8)
            }
            .padding(28)
            .background(Color(red: 0.12, green: 0.09, blue: 0.06))
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(red: 0.85, green: 0.68, blue: 0.35), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.8), radius: 25)
            .padding(.horizontal, 32)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }
    
    // MARK: - Game Logic
    
    private func handlePickaxeStrike(at tapLocation: CGPoint) {
        guard !isMountainDestroyed else { return }
        
        // Posisi beliung mengikuti sentuhan
        pickaxePosition = CGPoint(x: tapLocation.x + 40, y: tapLocation.y - 50)
        pickaxeRotation = -50
        
        // Animasi ayunan
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
        heavyImpact.impactOccurred(intensity: 0.8)
        triggerShake(intensity: 5.0)
        spawnSparks(at: point, count: 15)
        
        // Tambah retakan
        var newMark = RockImpactMark(center: point)
        addCrackBranches(to: &newMark.segments, center: point, intensity: mountainHits + 1)
        rockMarks.append(newMark)
        
        mountainHits += 1
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if mountainHits == 1 {
                dialogMessage = "Retakannya mulai muncul!"
                isShowingDialog = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { isShowingDialog = false }
                }
            } else if mountainHits == 3 {
                dialogMessage = "Batu mulai rapuh!"
                isShowingDialog = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { isShowingDialog = false }
                }
            }
        }
        
        if mountainHits >= maxHits {
            triggerMountainCollapse(at: point)
        }
    }
    
    private func triggerMountainCollapse(at point: CGPoint) {
        heavyImpact.impactOccurred(intensity: 1.0)
        triggerShake(intensity: 15.0)
        spawnSparks(at: point, count: 50)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            dialogMessage = "Garam berhasil ditambang!"
            isShowingDialog = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.6)) {
                isMountainDestroyed = true
            }
            successNotify.notificationOccurred(.success)
        }
    }
    
    private func addCrackBranches(to segments: inout [CrackSegment], center: CGPoint, intensity: Int) {
        let branchCount = Int.random(in: 4...7)
        let baseRadius: CGFloat = CGFloat(intensity) * 18.0
        
        for _ in 0..<branchCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let length = CGFloat.random(in: 20...baseRadius + 20)
            
            let mid = CGPoint(
                x: center.x + cos(angle) * (length * 0.5) + CGFloat.random(in: -5...5),
                y: center.y + sin(angle) * (length * 0.5) + CGFloat.random(in: -5...5)
            )
            let end = CGPoint(
                x: center.x + cos(angle) * length,
                y: center.y + sin(angle) * length
            )
            
            segments.append(CrackSegment(start: center, end: mid, width: CGFloat.random(in: 2.5...4.5)))
            segments.append(CrackSegment(start: mid, end: end, width: CGFloat.random(in: 1.0...2.5)))
        }
    }
    
    private func spawnSparks(at origin: CGPoint, count: Int) {
        let colors: [Color] = [.white, Color(red: 0.8, green: 0.9, blue: 1.0), .gray]
        for _ in 0..<count {
            let p = SaltDustParticle(
                position: origin,
                velocity: CGPoint(x: CGFloat.random(in: -60...60), y: CGFloat.random(in: -70...50)),
                scale: CGFloat.random(in: 0.8...2.5),
                color: colors.randomElement() ?? .white
            )
            particles.append(p)
        }
        
        withAnimation(.easeOut(duration: 0.5)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
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

// MARK: - Pickaxe Subview

public struct PickaxeToolView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // Gagang Kayu
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.45, green: 0.28, blue: 0.16), Color(red: 0.32, green: 0.19, blue: 0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 130)
                .overlay(Capsule().stroke(Color.black.opacity(0.5), lineWidth: 1.5))
                .rotationEffect(.degrees(32))
                .offset(x: 32, y: 40)
            
            // Cincin Besi
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color.gray, Color.black], startPoint: .top, endPoint: .bottom))
                .frame(width: 16, height: 16)
                .offset(y: -2)
            
            // Kepala Baja
            PickaxeHeadShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray, Color(red: 0.2, green: 0.2, blue: 0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 110, height: 50)
                .shadow(color: .black.opacity(0.5), radius: 5, x: 2, y: 4)
            
            // Kilauan Ujung
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
                .shadow(color: .white, radius: 5)
                .offset(x: -50, y: 18)
        }
        .frame(width: 140, height: 140)
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

public typealias RockSaltMiningView = RockSaltCarvingView

#Preview {
    RockSaltCarvingView()
}
