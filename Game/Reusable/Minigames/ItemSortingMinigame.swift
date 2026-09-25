import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration

public struct ItemSortingConfig: Sendable {
    public var requiredItems: Int
    public var allowTouchAnywhere: Bool
    public var autoDismissDelay: TimeInterval
    
    public init(
        requiredItems: Int = 6, // Jumlah umbi dinaikkan menjadi 6 buah
        allowTouchAnywhere: Bool = true,
        autoDismissDelay: TimeInterval = 2.0
    ) {
        self.requiredItems = requiredItems
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay
    }
}

// MARK: - SpriteKit Node

public final class ItemSortingMinigameNode: SKNode {
    
    public var onProgress: ((_ current: Int, _ total: Int) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?
    
    private let config: ItemSortingConfig
    private var isRunning: Bool = false
    private var isCompleted: Bool = false
    
    private var sortedCount: Int = 0
    
    // Drag & Wash State
    private var activeTuber: SKNode?
    private var isActiveTuberWashed: Bool = false
    private var originalTuberPosition: CGPoint = .zero
    
    // Multi-Stage Washing State (Kentang Paling Hitam: Cuci 3x)
    private var isCurrentTuberBlack: Bool = false
    private var requiredWashesForCurrentTuber: Int = 1
    private var currentWashStage: Int = 0
    private var accumulatedScrubDistance: CGFloat = 0.0
    private var lastScrubLocation: CGPoint?
    
    // Hierarchy nodes
    private let container = SKNode()
    private let workspaceNode = SKNode()
    
    // Parent Nodes untuk tiap zona (Atas ke Bawah)
    private let basketNode = SKNode()
    private let basinNode = SKNode()
    private let clothNode = SKNode()
    
    // Hitbox Area
    private let dirtyBasketZone = SKShapeNode()
    private let washBasinZone = SKShapeNode()
    private let cleanClothZone = SKShapeNode()
    
    private let activeItemsNode = SKNode()
    private let sortedItemsNode = SKNode()
    
    // Speech Bubble Dialog System (Membutuhkan kelas SpeechBubbleNode di project mu)
    private var activeSpeechBubble: SpeechBubbleNode?
    
    public init(config: ItemSortingConfig = ItemSortingConfig()) {
        self.config = config
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 800
        buildVisuals()
        spawnNewTuber()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Setup (Portrait Optimized)
    
    private func buildVisuals() {
        addChild(container)
        
        // 1. Latar Meja Kayu (Vertical Layout)
        container.addChild(workspaceNode)
        workspaceNode.zPosition = 1
        
        let bg = SKSpriteNode(color: SKColor(red: 0.06, green: 0.04, blue: 0.02, alpha: 1.0), size: CGSize(width: 5000, height: 5000))
        bg.zPosition = -10
        workspaceNode.addChild(bg)
        
        // Papan Meja Vertikal (Menyesuaikan HP)
        let boardH: CGFloat = 1600
        let plankW: CGFloat = 100
        for i in -4...4 {
            let plankX: CGFloat = CGFloat(i) * 102
            let plankRect = CGRect(x: -plankW/2, y: -boardH/2, width: plankW, height: boardH)
            let plank = SKShapeNode(rect: plankRect)
            
            let isDarker = i % 2 == 0
            plank.fillColor = isDarker ? SKColor(red: 0.26, green: 0.16, blue: 0.10, alpha: 1.0) : SKColor(red: 0.30, green: 0.20, blue: 0.12, alpha: 1.0)
            plank.strokeColor = SKColor(red: 0.08, green: 0.04, blue: 0.02, alpha: 0.9)
            plank.lineWidth = 4.0
            plank.position = CGPoint(x: plankX, y: 0)
            
            // Serat kayu
            for _ in 0...5 {
                let grain = SKShapeNode()
                let path = CGMutablePath()
                let startY = CGFloat.random(in: -boardH/2...0)
                path.move(to: CGPoint(x: CGFloat.random(in: -plankW/3...plankW/3), y: startY))
                path.addQuadCurve(to: CGPoint(x: CGFloat.random(in: -plankW/3...plankW/3), y: startY + CGFloat.random(in: 200...400)),
                                  control: CGPoint(x: CGFloat.random(in: -plankW/2...plankW/2), y: startY + 150))
                grain.path = path
                grain.strokeColor = SKColor(red: 0.12, green: 0.06, blue: 0.03, alpha: 0.3)
                grain.lineWidth = CGFloat.random(in: 2...5)
                plank.addChild(grain)
            }
            workspaceNode.addChild(plank)
        }
        
        // Vignette Shadow di tepi layar
        let vignette = SKShapeNode(rectOf: CGSize(width: 800, height: 1200))
        vignette.fillColor = .clear
        vignette.strokeColor = SKColor.black.withAlphaComponent(0.6)
        vignette.lineWidth = 150
        vignette.zPosition = -5
        workspaceNode.addChild(vignette)
        
        // --- ZONA KERJA POTRET (ATAS -> TENGAH -> BAWAH) ---
        
        // 2. ZONA ATAS (Keranjang Umbi) - Diangkat lebih ke atas
        basketNode.position = CGPoint(x: 0, y: 250)
        basketNode.zPosition = 2
        workspaceNode.addChild(basketNode)
        
        let basketW: CGFloat = 210
        let basketH: CGFloat = 160
        let basketShadow = SKShapeNode(ellipseOf: CGSize(width: basketW + 15, height: basketH + 15))
        basketShadow.fillColor = SKColor.black.withAlphaComponent(0.55)
        basketShadow.strokeColor = .clear
        basketShadow.position = CGPoint(x: 0, y: -12)
        basketNode.addChild(basketShadow)
        
        let basketBase = SKShapeNode(ellipseOf: CGSize(width: basketW, height: basketH))
        basketBase.fillColor = SKColor(red: 0.52, green: 0.38, blue: 0.24, alpha: 1.0)
        basketBase.strokeColor = SKColor(red: 0.28, green: 0.18, blue: 0.08, alpha: 1.0)
        basketBase.lineWidth = 8.0
        basketNode.addChild(basketBase)
        
        for i in -5...5 {
            let line1 = SKShapeNode()
            let p1 = CGMutablePath()
            p1.move(to: CGPoint(x: i * 18, y: -65))
            p1.addLine(to: CGPoint(x: i * 18, y: 65))
            line1.path = p1
            line1.strokeColor = SKColor(red: 0.38, green: 0.26, blue: 0.14, alpha: 0.8)
            line1.lineWidth = 4.0
            basketNode.addChild(line1)
            
            let line2 = SKShapeNode()
            let p2 = CGMutablePath()
            p2.move(to: CGPoint(x: -90, y: i * 14))
            p2.addLine(to: CGPoint(x: 90, y: i * 14))
            line2.path = p2
            line2.strokeColor = SKColor(red: 0.32, green: 0.20, blue: 0.10, alpha: 0.8)
            line2.lineWidth = 4.0
            basketNode.addChild(line2)
        }
        
        dirtyBasketZone.path = CGPath(ellipseIn: CGRect(x: -basketW/2, y: -basketH/2, width: basketW, height: basketH), transform: nil)
        dirtyBasketZone.fillColor = .clear
        dirtyBasketZone.strokeColor = .clear
        basketNode.addChild(dirtyBasketZone)
        
        // 3. ZONA TENGAH (Baskom Air)
        basinNode.position = CGPoint(x: 0, y: 30)
        basinNode.zPosition = 2
        workspaceNode.addChild(basinNode)
        
        let basinW: CGFloat = 280
        let basinH: CGFloat = 210
        let basinShadow = SKShapeNode(ellipseOf: CGSize(width: basinW + 20, height: basinH + 20))
        basinShadow.fillColor = SKColor.black.withAlphaComponent(0.5)
        basinShadow.strokeColor = .clear
        basinShadow.position = CGPoint(x: 0, y: -15)
        basinNode.addChild(basinShadow)
        
        let basinRim = SKShapeNode(ellipseOf: CGSize(width: basinW, height: basinH))
        basinRim.fillColor = SKColor(red: 0.42, green: 0.28, blue: 0.18, alpha: 1.0)
        basinRim.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.08, alpha: 1.0)
        basinRim.lineWidth = 14.0
        basinNode.addChild(basinRim)
        
        let basinInner = SKShapeNode(ellipseOf: CGSize(width: basinW - 35, height: basinH - 35))
        basinInner.fillColor = SKColor(red: 0.12, green: 0.08, blue: 0.06, alpha: 1.0)
        basinInner.strokeColor = .clear
        basinInner.position = CGPoint(x: 0, y: -6)
        basinNode.addChild(basinInner)
        
        let basinWater = SKShapeNode(ellipseOf: CGSize(width: basinW - 40, height: basinH - 40))
        basinWater.fillColor = SKColor(red: 0.15, green: 0.55, blue: 0.78, alpha: 0.85)
        basinWater.strokeColor = SKColor(red: 0.4, green: 0.75, blue: 0.95, alpha: 0.5)
        basinWater.lineWidth = 3.0
        basinNode.addChild(basinWater)
        
        let waterGlow = SKShapeNode(ellipseOf: CGSize(width: basinW - 70, height: basinH - 70))
        waterGlow.fillColor = SKColor(red: 0.5, green: 0.9, blue: 1.0, alpha: 0.2)
        waterGlow.strokeColor = .clear
        waterGlow.blendMode = .add
        waterGlow.position = CGPoint(x: -5, y: 5)
        basinNode.addChild(waterGlow)
        waterGlow.run(.repeatForever(.sequence([
            .scale(to: 1.1, duration: 2.2).applyTimingMode(.easeInEaseOut),
            .scale(to: 0.95, duration: 2.2).applyTimingMode(.easeInEaseOut)
        ])))
        
        washBasinZone.path = CGPath(ellipseIn: CGRect(x: -basinW/2, y: -basinH/2, width: basinW, height: basinH), transform: nil)
        washBasinZone.fillColor = .clear
        washBasinZone.strokeColor = .clear
        basinNode.addChild(washBasinZone)
        
        // 4. ZONA BAWAH (Kain Linen Bersih)
        clothNode.position = CGPoint(x: 0, y: -200)
        clothNode.zPosition = 2
        workspaceNode.addChild(clothNode)
        
        let clothW: CGFloat = 220
        let clothH: CGFloat = 170
        let clothRect = CGRect(x: -clothW/2, y: -clothH/2, width: clothW, height: clothH)
        
        let clothShadow = SKShapeNode(rect: clothRect, cornerRadius: 12)
        clothShadow.fillColor = SKColor.black.withAlphaComponent(0.35)
        clothShadow.strokeColor = .clear
        clothShadow.position = CGPoint(x: 5, y: -8)
        clothShadow.zRotation = 0.04
        clothNode.addChild(clothShadow)
        
        let clothShape = SKShapeNode(rect: clothRect, cornerRadius: 12)
        clothShape.fillColor = SKColor(red: 0.92, green: 0.90, blue: 0.85, alpha: 1.0)
        clothShape.strokeColor = SKColor(red: 0.78, green: 0.72, blue: 0.65, alpha: 1.0)
        clothShape.lineWidth = 3.5
        clothShape.zRotation = 0.04
        clothNode.addChild(clothShape)
        
        // Jahitan Tepi Kain
        let stitchRect = CGRect(x: -(clothW/2) + 10, y: -(clothH/2) + 10, width: clothW - 20, height: clothH - 20)
        let stitch = SKShapeNode(rect: stitchRect, cornerRadius: 8)
        let dashed = stitch.path?.copy(dashingWithPhase: 0, lengths: [8, 6])
        stitch.path = dashed
        stitch.strokeColor = SKColor(red: 0.72, green: 0.62, blue: 0.52, alpha: 0.85)
        stitch.lineWidth = 2.5
        stitch.zRotation = 0.04
        clothNode.addChild(stitch)
        
        // Lipatan Kain
        let fold = SKShapeNode()
        let foldPath = CGMutablePath()
        foldPath.move(to: CGPoint(x: -45, y: clothH/2 - 5))
        foldPath.addQuadCurve(to: CGPoint(x: 15, y: -clothH/2 + 5), control: CGPoint(x: 5, y: 0))
        fold.path = foldPath
        fold.strokeColor = SKColor(red: 0.85, green: 0.80, blue: 0.75, alpha: 0.6)
        fold.lineWidth = 5.0
        fold.zRotation = 0.04
        clothNode.addChild(fold)
        
        cleanClothZone.path = CGPath(roundedRect: clothRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
        cleanClothZone.fillColor = .clear
        cleanClothZone.strokeColor = .clear
        cleanClothZone.zRotation = 0.04
        clothNode.addChild(cleanClothZone)
        
        // 5. Layer Penempatan Umbi
        sortedItemsNode.zPosition = 3
        activeItemsNode.zPosition = 4
        workspaceNode.addChild(sortedItemsNode)
        workspaceNode.addChild(activeItemsNode)
    }
    
    // MARK: - Dialog System (SpeechBubbleNode Style)
    
    private func showDialog(name: String, message: String, isSuccess: Bool = false) {
        activeSpeechBubble?.popOut()
        activeSpeechBubble = nil
        
        let config = SpeechBubbleConfig(
            text: message,
            speaker: name,
            fontName: "AvenirNext-Bold",
            fontSize: 13,
            fontColor: .white,
            speakerColor: isSuccess ? SKColor(red: 0.45, green: 0.90, blue: 0.55, alpha: 1.0) : SKColor(red: 0.96, green: 0.83, blue: 0.48, alpha: 1.0),
            backgroundColor: SKColor(red: 0.08, green: 0.07, blue: 0.09, alpha: 0.96),
            crayonStrokeColor: isSuccess ? SKColor(red: 0.25, green: 0.70, blue: 0.35, alpha: 0.9) : SKColor(red: 0.85, green: 0.30, blue: 0.35, alpha: 0.9),
            padding: CGSize(width: 22, height: 14),
            maxWidth: 320,
            cornerRadius: 16
        )
        
        let bubble = SpeechBubbleNode(config: config, tailTipOffset: CGPoint(x: -70, y: -45))
        bubble.position = CGPoint(x: 0, y: -340)
        bubble.zPosition = 100
        container.addChild(bubble)
        bubble.popIn()
        activeSpeechBubble = bubble
        
        bubble.run(.sequence([
            .wait(forDuration: 2.0),
            .run { [weak self, weak bubble] in
                if self?.activeSpeechBubble == bubble {
                    self?.activeSpeechBubble = nil
                }
                bubble?.popOut()
            }
        ]))
    }
    
    // MARK: - Tuber Creators
    
    private func createTuberVisual() -> CGPath {
        let path = CGMutablePath()
        let w = CGFloat.random(in: 36...44) // Ukuran besar memuaskan
        let h = CGFloat.random(in: 48...60)
        
        path.move(to: CGPoint(x: 0, y: h/2))
        path.addQuadCurve(to: CGPoint(x: w/2, y: 0), control: CGPoint(x: w/2 + 10, y: h/4))
        path.addQuadCurve(to: CGPoint(x: 0, y: -h/2), control: CGPoint(x: w/2 + 5, y: -h/4))
        path.addQuadCurve(to: CGPoint(x: -w/2, y: 0), control: CGPoint(x: -w/2 - 8, y: -h/4))
        path.addQuadCurve(to: CGPoint(x: 0, y: h/2), control: CGPoint(x: -w/2 - 4, y: h/4))
        
        return path
    }
    
    private func spawnNewTuber() {
        guard sortedCount < config.requiredItems else { return }
        
        // Beberapa kentang (index 1, 3, dan 4) adalah kentang hitam yang butuh dicuci 3 kali
        let blackTuberIndices = [1, 3, 4]
        isCurrentTuberBlack = blackTuberIndices.contains(sortedCount)
        
        requiredWashesForCurrentTuber = isCurrentTuberBlack ? 3 : 1
        currentWashStage = 0
        accumulatedScrubDistance = 0
        isActiveTuberWashed = false
        
        let tuberNode = SKNode()
        setupTuberContent(tuberNode, isBlack: isCurrentTuberBlack)
        
        // Spawn di Keranjang (Atas)
        let spawnPos = CGPoint(x: basketNode.position.x + CGFloat.random(in: -30...30),
                               y: basketNode.position.y + CGFloat.random(in: -20...20))
        tuberNode.position = spawnPos
        tuberNode.zRotation = CGFloat.random(in: -0.6...0.6)
        tuberNode.name = "draggableTuber"
        
        activeItemsNode.addChild(tuberNode)
        
        tuberNode.setScale(0)
        tuberNode.run(.sequence([
            .scale(to: 1.15, duration: 0.22).applyTimingMode(.easeOut),
            .scale(to: 1.0, duration: 0.15).applyTimingMode(.easeIn)
        ]))
        
        // Variasi Dialog Minimalis
        if isCurrentTuberBlack {
            showDialog(name: "ANNETH", message: "Yang ini pekat, gosok 3 kali!", isSuccess: false)
        } else if sortedCount == 0 {
            showDialog(name: "ANNETH", message: "Cuci di baskom lalu taruh di kain!", isSuccess: false)
        }
    }
    
    private func setupTuberContent(_ tuberNode: SKNode, isBlack: Bool) {
        tuberNode.removeAllChildren()
        
        let shape = SKShapeNode(path: createTuberVisual())
        if isBlack {
            shape.fillColor = SKColor(red: 0.10, green: 0.07, blue: 0.05, alpha: 1.0)
            shape.strokeColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 1.0)
        } else {
            shape.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
            shape.strokeColor = SKColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 1.0)
        }
        shape.lineWidth = 3.5
        shape.name = "tuberShape"
        tuberNode.addChild(shape)
        
        let shadow = SKShapeNode(path: shape.path!)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 5, y: -7)
        shadow.zPosition = -1
        tuberNode.addChild(shadow)
        
        if isBlack {
            // Lapisan 1: Noda pekat dasar
            let dirtLayer1 = SKNode()
            dirtLayer1.name = "dirtLayer1"
            for _ in 0...8 {
                let dirt = SKShapeNode(circleOfRadius: CGFloat.random(in: 3.0...6.0))
                dirt.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.07, alpha: 0.95)
                dirt.strokeColor = .clear
                dirt.position = CGPoint(x: CGFloat.random(in: -16...16), y: CGFloat.random(in: -22...22))
                dirtLayer1.addChild(dirt)
            }
            tuberNode.addChild(dirtLayer1)
            
            // Lapisan 2: Kerak jelaga tebal
            let dirtLayer2 = SKNode()
            dirtLayer2.name = "dirtLayer2"
            for _ in 0...10 {
                let dirt = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 6...12)), cornerRadius: 4)
                dirt.fillColor = SKColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 0.95)
                dirt.strokeColor = .clear
                dirt.zRotation = CGFloat.random(in: -1.0...1.0)
                dirt.position = CGPoint(x: CGFloat.random(in: -18...18), y: CGFloat.random(in: -24...24))
                dirtLayer2.addChild(dirt)
            }
            tuberNode.addChild(dirtLayer2)
            
            // Lapisan 3: Lumpur hitam pekat paling luar
            let dirtLayer3 = SKNode()
            dirtLayer3.name = "dirtLayer3"
            for _ in 0...12 {
                let dirt = SKShapeNode(circleOfRadius: CGFloat.random(in: 4.5...8.5))
                dirt.fillColor = SKColor(red: 0.05, green: 0.03, blue: 0.02, alpha: 0.98)
                dirt.strokeColor = .clear
                dirt.position = CGPoint(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -26...26))
                dirtLayer3.addChild(dirt)
            }
            tuberNode.addChild(dirtLayer3)
        } else {
            let dirtLayer = SKNode()
            dirtLayer.name = "dirtLayer"
            for _ in 0...9 {
                let dirt = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5.5))
                dirt.fillColor = SKColor(red: 0.16, green: 0.08, blue: 0.04, alpha: 0.95)
                dirt.strokeColor = .clear
                dirt.position = CGPoint(x: CGFloat.random(in: -18...18), y: CGFloat.random(in: -25...25))
                dirtLayer.addChild(dirt)
            }
            tuberNode.addChild(dirtLayer)
        }
        
        let glint = SKShapeNode(ellipseOf: CGSize(width: 15, height: 7))
        glint.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.8)
        glint.strokeColor = .clear
        glint.zRotation = .pi / 4
        glint.position = CGPoint(x: -12, y: 18)
        glint.alpha = 0
        glint.name = "glint"
        tuberNode.addChild(glint)
    }
    
    // MARK: - Lifecycle & Touch Handling
    
    public func start() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true
        container.setScale(0.85)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.3),
            .scale(to: 1.0, duration: 0.4).applyTimingMode(.easeOut)
        ]))
        #if canImport(UIKit)
        HapticsService.shared.playSelection()
        #endif
    }
    
    #if canImport(UIKit)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first else { return }
        let location = touch.location(in: activeItemsNode)
        
        if let touchedNode = activeItemsNode.nodes(at: location).first(where: { $0.name == "draggableTuber" }) {
            activeTuber = touchedNode
            originalTuberPosition = touchedNode.position
            lastScrubLocation = touch.location(in: workspaceNode)
            
            touchedNode.run(.group([
                .scale(to: 1.35, duration: 0.15).applyTimingMode(.easeOut),
                .fadeAlpha(to: 0.95, duration: 0.1)
            ]))
            
            HapticsService.shared.playImpact(style: .light)
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first, let tuber = activeTuber else { return }
        tuber.position = touch.location(in: activeItemsNode)
        
        let currentTouchPosInWorkspace = touch.location(in: workspaceNode)
        let locInBasin = touch.location(in: basinNode)
        
        // Akurasi Hitbox: Jika berada di dalam baskom air, hitung scrubbing
        if washBasinZone.path?.contains(locInBasin) == true {
            if let lastLoc = lastScrubLocation {
                let dx = currentTouchPosInWorkspace.x - lastLoc.x
                let dy = currentTouchPosInWorkspace.y - lastLoc.y
                let dist = hypot(dx, dy)
                if dist > 2.0 {
                    handleScrubbingInBasin(deltaDist: dist, tuber: tuber)
                }
            }
        }
        lastScrubLocation = currentTouchPosInWorkspace
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first, let tuber = activeTuber else { return }
        
        let dropLocInCloth = touch.location(in: clothNode)
        let dropLocInBasin = touch.location(in: basinNode)
        let dropLocInBasket = touch.location(in: basketNode)
        let absoluteDropLoc = touch.location(in: workspaceNode)
        
        tuber.run(.group([
            .scale(to: 1.0, duration: 0.15).applyTimingMode(.easeOut),
            .fadeAlpha(to: 1.0, duration: 0.15)
        ]))
        
        // Logic Evaluasi
        if cleanClothZone.path?.contains(dropLocInCloth) == true {
            if isActiveTuberWashed {
                handleSuccessDrop(tuber: tuber, dropLoc: absoluteDropLoc)
            } else {
                if isCurrentTuberBlack {
                    if currentWashStage == 0 {
                        resetTuberAndScold(message: "Jangan taruh itu di kain! Masih hitam pekat dan berlumpur tebal!", tuber: tuber)
                    } else {
                        resetTuberAndScold(message: "Belum bersih, baru \(currentWashStage)/3!", tuber: tuber)
                    }
                } else {
                    resetTuberAndScold(message: "Cuci dulu di baskom!", tuber: tuber)
                }
            }
        } else if washBasinZone.path?.contains(dropLocInBasin) == true {
            if isActiveTuberWashed {
                showDialog(name: "ANNETH", message: "Sudah bersih, taruh di kain!", isSuccess: true)
            } else {
                showDialog(name: "ANNETH", message: "Gosok memutar sampai bersih!", isSuccess: false)
            }
        } else if dirtyBasketZone.path?.contains(dropLocInBasket) == true {
            tuber.run(.move(to: originalTuberPosition, duration: 0.25).applyTimingMode(.easeOut))
        } else {
            resetTuberAndScold(message: "Taruh di atas kain!", tuber: tuber)
        }
        
        activeTuber = nil
        lastScrubLocation = nil
    }
    #endif
    
    // MARK: - Game Logic & Scrubbing
    
    private func handleScrubbingInBasin(deltaDist: CGFloat, tuber: SKNode) {
        guard currentWashStage < requiredWashesForCurrentTuber else { return }
        
        accumulatedScrubDistance += deltaDist
        
        // Efek busa air halus saat menggosok
        if Int(accumulatedScrubDistance) % 30 < Int(deltaDist) + 3 {
            spawnScrubFoam(at: tuber.position)
            #if canImport(UIKit)
            HapticsService.shared.playImpact(style: .light)
            #endif
        }
        
        // Threshold jarak gosok:
        // Kentang biasa: 130 pt
        // Kentang paling hitam: 220 pt PER TAHAP
        let stageThreshold: CGFloat = isCurrentTuberBlack ? 220.0 : 130.0
        
        if accumulatedScrubDistance >= stageThreshold {
            accumulatedScrubDistance = 0.0
            advanceWashStage(tuber: tuber)
        }
    }
    
    private func advanceWashStage(tuber: SKNode) {
        currentWashStage += 1
        
        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .medium)
        #endif
        
        spawnSplashBubbles(at: tuber.position, count: 12)
        
        if isCurrentTuberBlack {
            switch currentWashStage {
            case 1:
                tuber.childNode(withName: "dirtLayer3")?.run(.sequence([
                    .fadeOut(withDuration: 0.2),
                    .removeFromParent()
                ]))
                if let shape = tuber.childNode(withName: "tuberShape") as? SKShapeNode {
                    shape.fillColor = SKColor(red: 0.22, green: 0.16, blue: 0.12, alpha: 1.0)
                }
                showDialog(name: "ANNETH", message: "Terus gosok!", isSuccess: false)
                
            case 2:
                tuber.childNode(withName: "dirtLayer2")?.run(.sequence([
                    .fadeOut(withDuration: 0.2),
                    .removeFromParent()
                ]))
                if let shape = tuber.childNode(withName: "tuberShape") as? SKShapeNode {
                    shape.fillColor = SKColor(red: 0.40, green: 0.28, blue: 0.18, alpha: 1.0)
                }
                showDialog(name: "ANNETH", message: "Hampir bersih, sekali lagi!", isSuccess: false)
                
            case 3:
                tuber.childNode(withName: "dirtLayer1")?.run(.sequence([
                    .fadeOut(withDuration: 0.2),
                    .removeFromParent()
                ]))
                if let shape = tuber.childNode(withName: "tuberShape") as? SKShapeNode {
                    shape.fillColor = SKColor(red: 0.90, green: 0.75, blue: 0.50, alpha: 1.0)
                    shape.strokeColor = SKColor(red: 0.65, green: 0.45, blue: 0.25, alpha: 1.0)
                }
                tuber.childNode(withName: "glint")?.run(.sequence([
                    .fadeIn(withDuration: 0.25),
                    .scale(to: 1.4, duration: 0.2),
                    .scale(to: 1.0, duration: 0.15)
                ]))
                isActiveTuberWashed = true
                #if canImport(UIKit)
                HapticsService.shared.playNotification(.success)
                #endif
                showDialog(name: "ANNETH", message: "Bersih! Taruh di kain.", isSuccess: true)
                
            default:
                break
            }
        } else {
            tuber.childNode(withName: "dirtLayer")?.run(.sequence([
                .fadeOut(withDuration: 0.2),
                .removeFromParent()
            ]))
            if let shape = tuber.childNode(withName: "tuberShape") as? SKShapeNode {
                shape.fillColor = SKColor(red: 0.88, green: 0.72, blue: 0.48, alpha: 1.0)
                shape.strokeColor = SKColor(red: 0.60, green: 0.40, blue: 0.22, alpha: 1.0)
            }
            tuber.childNode(withName: "glint")?.run(.fadeIn(withDuration: 0.2))
            isActiveTuberWashed = true
            #if canImport(UIKit)
            HapticsService.shared.playNotification(.success)
            #endif
            showDialog(name: "ANNETH", message: "Bersih! Taruh di kain.", isSuccess: true)
        }
    }
    
    private func spawnScrubFoam(at position: CGPoint) {
        for _ in 0...2 {
            let foam = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5.5))
            foam.fillColor = SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.7)
            foam.strokeColor = SKColor.white.withAlphaComponent(0.7)
            foam.lineWidth = 1.0
            foam.position = CGPoint(
                x: position.x + CGFloat.random(in: -25...25),
                y: position.y + CGFloat.random(in: -25...25)
            )
            foam.zPosition = 5
            activeItemsNode.addChild(foam)
            
            foam.run(.sequence([
                .group([
                    .scale(to: 1.4, duration: 0.25),
                    .fadeOut(withDuration: 0.25)
                ]),
                .removeFromParent()
            ]))
        }
    }
    
    private func spawnSplashBubbles(at position: CGPoint, count: Int = 10) {
        for _ in 0..<count {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...11))
            bubble.strokeColor = SKColor(red: 0.6, green: 0.95, blue: 1.0, alpha: 0.9)
            bubble.fillColor = SKColor(red: 0.8, green: 0.98, blue: 1.0, alpha: 0.5)
            bubble.lineWidth = 1.5
            bubble.position = position
            bubble.zPosition = 6
            activeItemsNode.addChild(bubble)
            
            let dx = CGFloat.random(in: -55...55)
            let dy = CGFloat.random(in: 15...65)
            
            bubble.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.45).applyTimingMode(.easeOut),
                    .scale(to: 0.1, duration: 0.45),
                    .fadeOut(withDuration: 0.45)
                ]),
                .removeFromParent()
            ]))
        }
    }
    
    private func handleSuccessDrop(tuber: SKNode, dropLoc: CGPoint) {
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.success)
        #endif
        
        tuber.removeFromParent()
        sortedItemsNode.addChild(tuber)
        
        // Letakkan dengan acak di area kain
        let clothX = clothNode.position.x + CGFloat.random(in: -50...50)
        let clothY = clothNode.position.y + CGFloat.random(in: -40...40)
        tuber.position = CGPoint(x: clothX, y: clothY)
        tuber.zRotation = CGFloat.random(in: -0.5...0.5)
        tuber.name = "sortedTuber"
        
        sortedCount += 1
        onProgress?(sortedCount, config.requiredItems)
        
        clothNode.run(.sequence([
            .moveBy(x: 0, y: -4, duration: 0.05),
            .moveBy(x: 0, y: 4, duration: 0.05)
        ]))
        
        if sortedCount >= config.requiredItems {
            finishEvent()
        } else {
            spawnNewTuber()
        }
    }
    
    private func resetTuberAndScold(message: String, tuber: SKNode) {
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.error)
        #endif
        
        isActiveTuberWashed = false
        currentWashStage = 0
        accumulatedScrubDistance = 0
        
        setupTuberContent(tuber, isBlack: isCurrentTuberBlack)
        
        tuber.run(.sequence([
            .move(to: originalTuberPosition, duration: 0.35).applyTimingMode(.easeOut),
            .scale(to: 1.25, duration: 0.1),
            .scale(to: 1.0, duration: 0.1)
        ]))
        
        showDialog(name: "ANNETH", message: message, isSuccess: false)
        
        // Shake screen sedikit
        container.run(.sequence([
            .moveBy(x: -8, y: 0, duration: 0.04),
            .moveBy(x: 16, y: 0, duration: 0.08),
            .moveBy(x: -8, y: 0, duration: 0.04)
        ]))
    }
    
    private func finishEvent() {
        isCompleted = true
        isRunning = false
        
        showDialog(name: "ANNETH", message: "Kerja bagus, Arthur!", isSuccess: true)
        
        let winGlow = SKShapeNode(rectOf: CGSize(width: 1600, height: 1600))
        winGlow.fillColor = SKColor(red: 0.6, green: 1.0, blue: 0.4, alpha: 0.3)
        winGlow.strokeColor = .clear
        winGlow.blendMode = .add
        winGlow.zPosition = 25
        container.addChild(winGlow)
        winGlow.run(.sequence([
            .scale(to: 1.2, duration: 0.5).applyTimingMode(.easeOut),
            .fadeOut(withDuration: 0.6),
            .removeFromParent()
        ]))
        
        onComplete?(true)
        
        if config.autoDismissDelay > 0 {
            run(.sequence([
                .wait(forDuration: config.autoDismissDelay + 1.0),
                .group([
                    .fadeOut(withDuration: 0.5),
                    .scale(to: 0.9, duration: 0.5).applyTimingMode(.easeIn)
                ]),
                .run { [weak self] in
                    self?.onDismiss?()
                    self?.removeFromParent()
                }
            ]))
        }
    }
    
    public func cancel() {
        isRunning = false
        removeAllActions()
        removeFromParent()
    }
}

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("Item Sorting Naratif (Portrait)") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 393, height: 852)) // iPhone 14 Pro Portrait size
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 1.0)
        
        func spawn() {
            // Memulai game dengan total 6 umbi
            let minigame = ItemSortingMinigameNode(config: ItemSortingConfig(requiredItems: 6))
            minigame.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
            minigame.onDismiss = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { spawn() }
            }
            scene.addChild(minigame)
            minigame.start()
        }
        
        spawn()
        return scene
    }())
    .ignoresSafeArea()
}
#endif
