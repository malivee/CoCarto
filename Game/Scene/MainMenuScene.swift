import SpriteKit
import SwiftUI

final class MainMenuScene: SKScene {
    private enum NodeName {
        static let play = "MainMenuPlay"
    }

    private let palette = (
        background: SKColor(red: 0.025, green: 0.075, blue: 0.12, alpha: 1),
        backgroundLight: SKColor(red: 0.055, green: 0.16, blue: 0.20, alpha: 1),
        parchment: SKColor(red: 0.96, green: 0.90, blue: 0.74, alpha: 1),
        ink: SKColor(red: 0.16, green: 0.13, blue: 0.10, alpha: 1),
        gold: SKColor(red: 0.94, green: 0.68, blue: 0.19, alpha: 1)
    )

    private var playButton: SKNode?
    private var isPlayPressed = false
    private var hasBuiltScene = false

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        buildScene(animated: true)
        hasBuiltScene = true
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard hasBuiltScene, oldSize != size else { return }
        buildScene(animated: false)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        setPlayPressed(nodes(at: location).contains(where: { $0.name == NodeName.play }))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        setPlayPressed(nodes(at: location).contains(where: { $0.name == NodeName.play }))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else {
            setPlayPressed(false)
            return
        }
        
        let shouldPlay = isPlayPressed && nodes(at: location).contains(where: { $0.name == NodeName.play })
        setPlayPressed(false)
        guard shouldPlay else { return }

        // Tambahkan efek haptic saat tombol ditekan (iOS)
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif

        // AudioService.shared.playSFX("PaperMap") // Pastikan class AudioService tersedia di project Anda
        isUserInteractionEnabled = false
        
        // Transisi ke GameScene
        let scene = SKScene(size: size) // Ganti SKScene(size: size) dengan GameScene(size: size) milik Anda
        scene.backgroundColor = palette.background
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: .fade(withDuration: 0.45))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPlayPressed(false)
    }

    private func buildScene(animated: Bool) {
        removeAllChildren()
        backgroundColor = palette.background

        addBackground()
        addBranding(animated: animated)
        addMapVignette(animated: animated)

        let button = makePlayButton()
        button.position = CGPoint(x: size.width / 2, y: max(100, size.height * 0.18))
        playButton = button
        addChild(button)

        if animated {
            button.alpha = 0
            button.position.y -= 20
            let appear = SKAction.group([
                .fadeIn(withDuration: 0.5),
                .moveBy(x: 0, y: 20, duration: 0.5)
            ])
            appear.timingMode = .easeOut
            button.run(.sequence([.wait(forDuration: 0.45), appear]))
        }
    }

    private func addBackground() {
        let wash = SKShapeNode(circleOfRadius: max(size.width, size.height) * 0.46)
        wash.position = CGPoint(x: size.width * 0.72, y: size.height * 0.58)
        wash.fillColor = palette.backgroundLight.withAlphaComponent(0.42)
        wash.strokeColor = .clear
        wash.zPosition = -20
        addChild(wash)

        let horizon = SKShapeNode(ellipseOf: CGSize(width: size.width * 1.35, height: size.height * 0.25))
        horizon.position = CGPoint(x: size.width / 2, y: size.height * 0.40)
        horizon.fillColor = SKColor.black.withAlphaComponent(0.16)
        horizon.strokeColor = palette.parchment.withAlphaComponent(0.08)
        horizon.lineWidth = 1
        horizon.zPosition = -10
        addChild(horizon)

        // Efek partikel debu/bintang yang bersinar (Glimmer)
        let dotCount = min(24, max(12, Int(size.height / 50)))
        for index in 0..<dotCount {
            let isLarge = index.isMultiple(of: 3)
            let radius: CGFloat = isLarge ? 2.5 : 1.25
            let dot = SKShapeNode(circleOfRadius: radius)
            
            let xSeed = CGFloat((index * 73 + 29) % 101) / 100
            let ySeed = CGFloat((index * 47 + 17) % 97) / 96
            
            dot.position = CGPoint(x: size.width * xSeed, y: size.height * (0.22 + ySeed * 0.72))
            dot.fillColor = palette.parchment.withAlphaComponent(isLarge ? 0.40 : 0.16)
            dot.strokeColor = .clear
            dot.zPosition = -5
            
            // Animasi melayang
            let drift = SKAction.moveBy(x: 0, y: 10 + CGFloat(index % 4), duration: 3.5 + Double(index % 5) * 0.3)
            drift.timingMode = .easeInEaseOut
            dot.run(.repeatForever(.sequence([drift, drift.reversed()])))
            
            // Animasi berkedip (Glimmer)
            if isLarge {
                let fade = SKAction.sequence([
                    .fadeAlpha(to: 0.1, duration: Double.random(in: 1.0...2.0)),
                    .fadeAlpha(to: 0.5, duration: Double.random(in: 1.0...2.0))
                ])
                dot.run(.repeatForever(fade))
            }
            addChild(dot)
        }
    }

    private func addBranding(animated: Bool) {
        let brand = SKNode()
        brand.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        brand.zPosition = 20
        addChild(brand)

        

        // Efek Glow Emas di belakang Judul Utama
        let glowNode = SKShapeNode(ellipseOf: CGSize(width: 280, height: 80))
        glowNode.fillColor = palette.gold.withAlphaComponent(0.15)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: 10)
        glowNode.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.05, duration: 1.5),
            .fadeAlpha(to: 0.15, duration: 1.5)
        ])))
        brand.addChild(glowNode)

        let titleShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleShadow.text = "COCARTO"
        titleShadow.fontSize = min(62, size.width * 0.155)
        titleShadow.fontColor = SKColor.black.withAlphaComponent(0.45)
        titleShadow.position = CGPoint(x: 3, y: -4)
        titleShadow.verticalAlignmentMode = .center
        brand.addChild(titleShadow)

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "COCARTO"
        title.fontSize = titleShadow.fontSize
        title.fontColor = palette.parchment
        title.verticalAlignmentMode = .center
        brand.addChild(title)

        let leftRule = SKShapeNode(rectOf: CGSize(width: 45, height: 2), cornerRadius: 1)
        leftRule.position = CGPoint(x: -74, y: -46)
        leftRule.fillColor = palette.gold
        leftRule.strokeColor = .clear
        brand.addChild(leftRule)

        let seal = SKShapeNode(circleOfRadius: 5)
        seal.position.y = -46
        seal.fillColor = palette.gold
        seal.strokeColor = palette.parchment
        seal.lineWidth = 1.5
        brand.addChild(seal)

        let rightRule = leftRule.copy() as! SKShapeNode
        rightRule.position.x = 74
        brand.addChild(rightRule)

        

        guard animated else { return }
        brand.alpha = 0
        brand.position.y += 15
        let appear = SKAction.group([
            .fadeIn(withDuration: 0.65),
            .moveBy(x: 0, y: -15, duration: 0.65)
        ])
        appear.timingMode = .easeOut
        brand.run(appear)
    }

    private func addMapVignette(animated: Bool) {
        let vignette = SKNode()
        vignette.position = CGPoint(x: size.width / 2, y: size.height * 0.46)
        vignette.zPosition = 10
        addChild(vignette)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: min(310, size.width * 0.8), height: 64))
        shadow.position.y = -52
        shadow.fillColor = SKColor.black.withAlphaComponent(0.38)
        shadow.strokeColor = .clear
        vignette.addChild(shadow)

        let tileSize = min(120, size.width * 0.31)
        let tiles: [(String, CGPoint, CGFloat)] = [
            ("tile 2", CGPoint(x: -tileSize * 0.46, y: -5), -0.12),
            ("tile 1", CGPoint(x: tileSize * 0.38, y: 4), 0.10),
            ("tile 3", CGPoint(x: 0, y: tileSize * 0.35), 0)
        ]
        
        for (index, tileInfo) in tiles.enumerated() {
            // Gunakan fallback solid block jika gambar tile tidak ditemukan di Assets
            let tile = SKSpriteNode(color: palette.parchment, size: CGSize(width: tileSize, height: tileSize))
            if let texture = SKTexture(imageNamed: tileInfo.0).cgImage() != nil ? SKTexture(imageNamed: tileInfo.0) : nil {
                tile.texture = texture
            }
            
            tile.position = tileInfo.1
            tile.zRotation = tileInfo.2
            tile.zPosition = CGFloat(index)
            
            // Tambahkan bingkai putih agar terlihat seperti kartu/map
            let tileBorder = SKShapeNode(rectOf: tile.size, cornerRadius: 4)
            tileBorder.strokeColor = palette.ink.withAlphaComponent(0.3)
            tileBorder.lineWidth = 1.5
            tile.addChild(tileBorder)
            
            vignette.addChild(tile)
        }

        let house = SKSpriteNode(color: palette.gold.withAlphaComponent(0.8), size: CGSize(width: tileSize * 0.68, height: tileSize * 0.48))
        if let tex = SKTexture(imageNamed: "rumahArthur").cgImage() != nil ? SKTexture(imageNamed: "rumahArthur") : nil { house.texture = tex; house.colorBlendFactor = 0 }
        house.position = CGPoint(x: -tileSize * 0.12, y: tileSize * 0.40)
        house.zPosition = 8
        vignette.addChild(house)

        let well = SKSpriteNode(color: palette.ink.withAlphaComponent(0.6), size: CGSize(width: tileSize * 0.28, height: tileSize * 0.28))
        if let tex = SKTexture(imageNamed: "sumur").cgImage() != nil ? SKTexture(imageNamed: "sumur") : nil { well.texture = tex; well.colorBlendFactor = 0 }
        well.position = CGPoint(x: tileSize * 0.48, y: tileSize * 0.10)
        well.zPosition = 9
        vignette.addChild(well)

        let bobUp = SKAction.moveBy(x: 0, y: 8, duration: 2.2)
        bobUp.timingMode = .easeInEaseOut
        vignette.run(.repeatForever(.sequence([bobUp, bobUp.reversed()])), withKey: "menuFloat")

        guard animated else { return }
        vignette.alpha = 0
        vignette.setScale(0.92)
        let reveal = SKAction.group([
            .fadeIn(withDuration: 0.75),
            .scale(to: 1, duration: 0.75)
        ])
        reveal.timingMode = .easeOut
        vignette.run(.sequence([.wait(forDuration: 0.15), reveal]))
    }

    private func makePlayButton() -> SKNode {
        let root = SKNode()
        root.name = NodeName.play

        let buttonWidth = min(300, size.width - 56)
        
        // Efek Aura berdenyut di sekitar tombol
        let pulseGlow = SKShapeNode(rectOf: CGSize(width: buttonWidth + 8, height: 72), cornerRadius: 22)
        pulseGlow.fillColor = palette.gold.withAlphaComponent(0.25)
        pulseGlow.strokeColor = .clear
        pulseGlow.zPosition = -2
        let pulseAnim = SKAction.sequence([
            .fadeAlpha(to: 0.05, duration: 1.2),
            .fadeAlpha(to: 0.35, duration: 1.2)
        ])
        pulseAnim.timingMode = .easeInEaseOut
        pulseGlow.run(.repeatForever(pulseAnim))
        root.addChild(pulseGlow)

        // Bayangan Utama (Drop Shadow)
        let shadow = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: 64), cornerRadius: 20)
        shadow.position.y = -6
        shadow.fillColor = SKColor.black.withAlphaComponent(0.35)
        shadow.strokeColor = .clear
        shadow.zPosition = -1
        root.addChild(shadow)

        let background = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: 64), cornerRadius: 20)
        background.name = NodeName.play
        background.fillColor = palette.gold
        background.strokeColor = palette.parchment
        background.lineWidth = 2.5
        root.addChild(background)

        let innerBorder = SKShapeNode(rectOf: CGSize(width: buttonWidth - 10, height: 54), cornerRadius: 15)
        innerBorder.name = NodeName.play
        innerBorder.fillColor = .clear
        innerBorder.strokeColor = palette.ink.withAlphaComponent(0.3)
        innerBorder.lineWidth = 1.5
        root.addChild(innerBorder)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = NodeName.play
        label.text = "MULAI PETUALANGAN"
        label.fontSize = min(18, size.width * 0.046)
        label.fontColor = palette.ink
        label.verticalAlignmentMode = .center
        label.position.y = 1
        label.zPosition = 2
        root.addChild(label)
        
        return root
    }

    private func setPlayPressed(_ pressed: Bool) {
        guard pressed != isPlayPressed else { return }
        isPlayPressed = pressed
        playButton?.removeAction(forKey: "pressFeedback")
        
        let targetScale: CGFloat = pressed ? 0.94 : 1.0
        let targetAlpha: CGFloat = pressed ? 0.8 : 1.0
        
        let action = SKAction.group([
            .scale(to: targetScale, duration: 0.1),
            .fadeAlpha(to: targetAlpha, duration: 0.1)
        ])
        action.timingMode = .easeOut
        playButton?.run(action, withKey: "pressFeedback")
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
struct MainMenuScene_Previews: PreviewProvider {
    static var previews: some View {
        // Menggunakan ukuran standar iPhone (misal: iPhone 14 Pro)
        SpriteView(scene: {
            let scene = MainMenuScene(size: CGSize(width: 393, height: 852))
            scene.scaleMode = .resizeFill
            return scene
        }())
        .ignoresSafeArea()
    }
}
#endif
