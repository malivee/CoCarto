import SpriteKit
import SwiftUI

final class ToBeContinuedScene: SKScene {
    private enum NodeName {
        static let replay = "EndingReplay"
        static let mainMenu = "EndingMainMenu"
    }

    // CoCarto Official Palette (Same as Main Menu)
    private let palette = (
        background: SKColor(red: 0.025, green: 0.075, blue: 0.12, alpha: 1),
        backgroundLight: SKColor(red: 0.055, green: 0.16, blue: 0.20, alpha: 1),
        parchment: SKColor(red: 0.96, green: 0.90, blue: 0.74, alpha: 1),
        ink: SKColor(red: 0.16, green: 0.13, blue: 0.10, alpha: 1),
        gold: SKColor(red: 0.94, green: 0.68, blue: 0.19, alpha: 1)
    )

    private var replayButton: SKNode?
    private var menuButton: SKNode?
    private var pressedButtonName: String?
    private var hasBuiltScene = false
    
    // Lock screen interactions until animations complete
    private var isInteractionEnabled = false

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        buildScene()
        hasBuiltScene = true
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard hasBuiltScene, oldSize != size else { return }
        buildScene()
    }

    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isInteractionEnabled, let location = touches.first?.location(in: self) else { return }
        updatePressedButton(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isInteractionEnabled, let location = touches.first?.location(in: self) else { return }
        updatePressedButton(at: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isInteractionEnabled, let location = touches.first?.location(in: self) else {
            clearPressedButton()
            return
        }
        
        let stack = nodes(at: location)
        let selectedName = pressedButtonName
        clearPressedButton()

        if selectedName == NodeName.replay && stack.contains(where: { $0.name == NodeName.replay }) {
            triggerAction(isReplay: true)
        } else if selectedName == NodeName.mainMenu && stack.contains(where: { $0.name == NodeName.mainMenu }) {
            triggerAction(isReplay: false)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearPressedButton()
    }

    // MARK: - Scene Building (Cinematic Reveal)

    private func buildScene() {
        removeAllChildren()
        backgroundColor = palette.background

        addBackground()
        addHeaderSequence()
        addJournalCardSequence()
        addButtonsSequence()
        
        // Unlock interactions after 4.5 seconds
        let unlockWait = SKAction.wait(forDuration: 4.5)
        let unlockRun = SKAction.run { [weak self] in self?.isInteractionEnabled = true }
        run(SKAction.sequence([unlockWait, unlockRun]))
    }

    private func addBackground() {
        let wash = SKShapeNode(circleOfRadius: max(size.width, size.height) * 0.46)
        wash.position = CGPoint(x: size.width * 0.5, y: size.height * 0.58)
        wash.fillColor = palette.backgroundLight.withAlphaComponent(0.42)
        wash.strokeColor = .clear
        wash.zPosition = -20
        addChild(wash)

        let horizon = SKShapeNode(ellipseOf: CGSize(width: size.width * 1.35, height: size.height * 0.25))
        horizon.position = CGPoint(x: size.width / 2, y: size.height * 0.20)
        horizon.fillColor = SKColor.black.withAlphaComponent(0.16)
        horizon.strokeColor = palette.parchment.withAlphaComponent(0.08)
        horizon.lineWidth = 1
        horizon.zPosition = -10
        addChild(horizon)

        let dotCount = min(24, max(12, Int(size.height / 50)))
        for index in 0..<dotCount {
            let isLarge = index.isMultiple(of: 3)
            let radius: CGFloat = isLarge ? 2.5 : 1.25
            let dot = SKShapeNode(circleOfRadius: radius)
            
            let xSeed = CGFloat((index * 73 + 29) % 101) / 100
            let ySeed = CGFloat((index * 47 + 17) % 97) / 96
            
            dot.position = CGPoint(x: size.width * xSeed, y: size.height * (0.10 + ySeed * 0.90))
            dot.fillColor = palette.parchment.withAlphaComponent(isLarge ? 0.40 : 0.16)
            dot.strokeColor = .clear
            dot.zPosition = -5
            
            let drift = SKAction.moveBy(x: 0, y: 10 + CGFloat(index % 4), duration: 3.5 + Double(index % 5) * 0.3)
            drift.timingMode = .easeInEaseOut
            dot.run(.repeatForever(.sequence([drift, drift.reversed()])))
            
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

    private func addHeaderSequence() {
        let header = SKNode()
        header.position = CGPoint(x: size.width / 2, y: size.height * 0.82)
        header.zPosition = 20
        addChild(header)

        // Gold Glow behind the title
        let glowNode = SKShapeNode(ellipseOf: CGSize(width: 320, height: 80))
        glowNode.fillColor = palette.gold.withAlphaComponent(0.15)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: 0)
        glowNode.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.05, duration: 1.5),
            .fadeAlpha(to: 0.15, duration: 1.5)
        ])))
        header.addChild(glowNode)

        // "CHAPTER ONE COMPLETE"
        let eyebrowLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        eyebrowLabel.text = "C H A P T E R   O N E   C O M P L E T E"
        eyebrowLabel.fontSize = min(11, size.width * 0.03)
        eyebrowLabel.fontColor = palette.gold
        eyebrowLabel.verticalAlignmentMode = .center
        eyebrowLabel.position.y = 45
        eyebrowLabel.alpha = 0
        header.addChild(eyebrowLabel)
        
        let leftRule = SKShapeNode(rectOf: CGSize(width: 35, height: 2), cornerRadius: 1)
        leftRule.position = CGPoint(x: -115, y: 45)
        leftRule.fillColor = palette.gold
        leftRule.strokeColor = .clear
        leftRule.alpha = 0
        header.addChild(leftRule)

        let rightRule = leftRule.copy() as! SKShapeNode
        rightRule.position.x = 115
        header.addChild(rightRule)
        
        let fadeInChap = SKAction.fadeIn(withDuration: 1.0)
        let moveChap = SKAction.moveBy(x: 0, y: 5, duration: 1.0)
        fadeInChap.timingMode = .easeOut; moveChap.timingMode = .easeOut
        
        let eyebrowGroup = SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.group([fadeInChap, moveChap])
        ])
        eyebrowLabel.run(eyebrowGroup)
        leftRule.run(eyebrowGroup)
        rightRule.run(eyebrowGroup)

        // TO BE CONTINUED Title
        let titleShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleShadow.text = "TO BE CONTINUED"
        titleShadow.fontSize = min(36, size.width * 0.085)
        titleShadow.fontColor = SKColor.black.withAlphaComponent(0.45)
        titleShadow.position = CGPoint(x: 3, y: -4)
        titleShadow.verticalAlignmentMode = .center
        titleShadow.alpha = 0
        header.addChild(titleShadow)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = "TO BE CONTINUED"
        titleLabel.fontSize = titleShadow.fontSize
        titleLabel.fontColor = palette.parchment
        titleLabel.verticalAlignmentMode = .center
        titleLabel.alpha = 0
        header.addChild(titleLabel)
        
        let fadeInTitle = SKAction.fadeIn(withDuration: 1.2)
        let scaleTitle = SKAction.scale(to: 1.05, duration: 2.0)
        fadeInTitle.timingMode = .easeOut; scaleTitle.timingMode = .easeOut
        
        let titleGroup = SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.group([fadeInTitle, scaleTitle])
        ])
        
        titleLabel.run(titleGroup)
        titleShadow.run(titleGroup)
    }

    private func addJournalCardSequence() {
        let cardContainer = SKNode()
        cardContainer.position = CGPoint(x: size.width / 2, y: size.height * 0.50)
        cardContainer.zPosition = 10
        addChild(cardContainer)

        let cardWidth = min(340, size.width * 0.88)
        let cardHeight: CGFloat = 220

        // Parchment Paper
        let paper = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 8)
        paper.fillColor = palette.parchment
        paper.strokeColor = palette.gold.withAlphaComponent(0.6)
        paper.lineWidth = 2.0
        paper.alpha = 0
        paper.position.y -= 15
        
        // Paper Shadow
        let paperShadow = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 8)
        paperShadow.position.y = -8
        paperShadow.fillColor = SKColor.black.withAlphaComponent(0.38)
        paperShadow.strokeColor = .clear
        paperShadow.zPosition = -1
        paper.addChild(paperShadow)
        
        // Ink Border
        let inkBorder = SKShapeNode(rectOf: CGSize(width: cardWidth - 16, height: cardHeight - 16), cornerRadius: 4)
        inkBorder.fillColor = .clear
        inkBorder.strokeColor = palette.ink.withAlphaComponent(0.2)
        inkBorder.lineWidth = 1.0
        paper.addChild(inkBorder)
        
        cardContainer.addChild(paper)
        
        // Floating Animation
        let bobUp = SKAction.moveBy(x: 0, y: 5, duration: 2.5)
        bobUp.timingMode = .easeInEaseOut
        cardContainer.run(.repeatForever(.sequence([bobUp, bobUp.reversed()])))
        
        let fadeCard = SKAction.fadeIn(withDuration: 0.8)
        let moveCard = SKAction.moveBy(x: 0, y: 15, duration: 0.8)
        fadeCard.timingMode = .easeOut; moveCard.timingMode = .easeOut
        paper.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.group([fadeCard, moveCard])
        ]))

        // Journal Title
        let logTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        logTitle.text = "JOURNAL ENTRIES"
        logTitle.fontSize = 12
        logTitle.fontColor = palette.ink.withAlphaComponent(0.6)
        logTitle.position = CGPoint(x: 0, y: 75)
        logTitle.alpha = 0
        cardContainer.addChild(logTitle)
        
        let fadeLog = SKAction.fadeIn(withDuration: 0.5)
        logTitle.run(SKAction.sequence([SKAction.wait(forDuration: 2.2), fadeLog]))

        // Lore Flavour Text
        let storyText = SKLabelNode(fontNamed: "AvenirNext-Italic")
        storyText.text = "\"From the old well to the salt mines,\ntales of the outside world begin to echo...\""
        storyText.fontSize = 13
        storyText.fontColor = palette.ink
        storyText.numberOfLines = 2
        storyText.horizontalAlignmentMode = .center
        storyText.position = CGPoint(x: 0, y: 35)
        storyText.alpha = 0
        cardContainer.addChild(storyText)
        storyText.run(SKAction.sequence([SKAction.wait(forDuration: 2.5), fadeLog]))

        // Divider Line
        let divider = SKShapeNode(rectOf: CGSize(width: cardWidth - 80, height: 1))
        divider.fillColor = palette.ink.withAlphaComponent(0.15)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: 0, y: 20)
        divider.alpha = 0
        cardContainer.addChild(divider)
        divider.run(SKAction.sequence([SKAction.wait(forDuration: 2.5), fadeLog]))

        // Milestones translated based on your script
        let milestones = [
            "Helped Kenneth & the Villagers",
            "Heard the Tale of the 'Salt Sea'",
            "Learned the Safe Boundaries"
        ]
        
        let startY: CGFloat = -5
        let spacing: CGFloat = 30

        for (index, text) in milestones.enumerated() {
            let rowNode = SKNode()
            rowNode.position.y = startY - (CGFloat(index) * spacing)
            rowNode.alpha = 0
            cardContainer.addChild(rowNode)

            // Wax Stamp Checkmark
            let waxStamp = SKShapeNode(circleOfRadius: 10)
            waxStamp.fillColor = palette.gold
            waxStamp.strokeColor = palette.ink.withAlphaComponent(0.8)
            waxStamp.lineWidth = 1.0
            waxStamp.position = CGPoint(x: -cardWidth/2 + 45, y: 0)
            rowNode.addChild(waxStamp)
            
            let checkMark = SKLabelNode(fontNamed: "AvenirNext-Bold")
            checkMark.text = "✓"
            checkMark.fontSize = 12
            checkMark.fontColor = palette.ink
            checkMark.verticalAlignmentMode = .center
            checkMark.position = CGPoint(x: -cardWidth/2 + 45, y: 1)
            rowNode.addChild(checkMark)

            // Achievement Text
            let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            label.text = text
            label.fontSize = 14
            label.fontColor = palette.ink.withAlphaComponent(0.9)
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: -cardWidth/2 + 65, y: 0)
            rowNode.addChild(label)

            // Stamp Animation
            let delay = 3.0 + (Double(index) * 0.4)
            let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
            let scaleNormal = SKAction.scale(to: 1.0, duration: 0.15)
            let fadeIn = SKAction.fadeIn(withDuration: 0.15)
            scaleUp.timingMode = .easeOut; scaleNormal.timingMode = .easeIn
            
            let stampAction = SKAction.group([
                fadeIn,
                SKAction.sequence([scaleUp, scaleNormal])
            ])
            
            rowNode.setScale(0.5)
            rowNode.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                stampAction,
                SKAction.run {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }
            ]))
        }
    }

    private func addButtonsSequence() {
        // Primary Button: MAIN MENU
        let menuBtn = makeButton(title: "MAIN MENU", name: NodeName.mainMenu, isPrimary: true)
        menuBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        menuButton = menuBtn
        addChild(menuBtn)

        // Secondary Button: REPLAY CHAPTER
        let replayBtn = makeButton(title: "REPLAY CHAPTER", name: NodeName.replay, isPrimary: false)
        replayBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.09)
        replayButton = replayBtn
        addChild(replayBtn)

        // Button Reveal Animation
        for (index, button) in [menuBtn, replayBtn].enumerated() {
            button.alpha = 0
            button.position.y -= 15
            
            let delay = 4.6 + (Double(index) * 0.2)
            let fadeBtn = SKAction.fadeIn(withDuration: 0.6)
            let moveBtn = SKAction.moveBy(x: 0, y: 15, duration: 0.6)
            fadeBtn.timingMode = .easeOut; moveBtn.timingMode = .easeOut
            
            button.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([fadeBtn, moveBtn])
            ]))
        }
    }

    private func makeButton(title: String, name: String, isPrimary: Bool) -> SKNode {
        let root = SKNode()
        root.name = name

        let buttonWidth = min(300, size.width - 56)
        let buttonHeight: CGFloat = 60

        if isPrimary {
            // Gold Pulse Effect
            let pulseGlow = SKShapeNode(rectOf: CGSize(width: buttonWidth + 8, height: buttonHeight + 8), cornerRadius: 22)
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

            // Drop Shadow
            let shadow = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 20)
            shadow.position.y = -6
            shadow.fillColor = SKColor.black.withAlphaComponent(0.35)
            shadow.strokeColor = .clear
            shadow.zPosition = -1
            root.addChild(shadow)

            // Gold Background
            let background = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 20)
            background.name = name
            background.fillColor = palette.gold
            background.strokeColor = palette.parchment
            background.lineWidth = 2.5
            root.addChild(background)

            // Inner Ink Border
            let innerBorder = SKShapeNode(rectOf: CGSize(width: buttonWidth - 10, height: buttonHeight - 10), cornerRadius: 15)
            innerBorder.name = name
            innerBorder.fillColor = .clear
            innerBorder.strokeColor = palette.ink.withAlphaComponent(0.3)
            innerBorder.lineWidth = 1.5
            root.addChild(innerBorder)
            
        } else {
            // Outline Button for Secondary
            let background = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight - 10), cornerRadius: (buttonHeight - 10) / 2)
            background.name = name
            background.fillColor = .clear
            background.strokeColor = palette.parchment.withAlphaComponent(0.6)
            background.lineWidth = 1.5
            root.addChild(background)
        }

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = name
        label.text = title
        label.fontSize = min(16, size.width * 0.042)
        label.fontColor = isPrimary ? palette.ink : palette.parchment
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position.y = 1
        label.zPosition = 2
        root.addChild(label)
        
        return root
    }

    // MARK: - Interactions

    private func updatePressedButton(at location: CGPoint) {
        let stack = nodes(at: location)
        let nextName: String?
        
        if stack.contains(where: { $0.name == NodeName.replay }) {
            nextName = NodeName.replay
        } else if stack.contains(where: { $0.name == NodeName.mainMenu }) {
            nextName = NodeName.mainMenu
        } else {
            nextName = nil
        }
        
        guard nextName != pressedButtonName else { return }
        clearPressedButton()
        
        pressedButtonName = nextName
        if let btn = buttonNode(named: nextName) {
            let scaleDown = SKAction.scale(to: 0.94, duration: 0.1)
            let fadeOut = SKAction.fadeAlpha(to: 0.8, duration: 0.1)
            scaleDown.timingMode = .easeOut; fadeOut.timingMode = .easeOut
            btn.run(SKAction.group([scaleDown, fadeOut]), withKey: "pressFeedback")
        }
    }

    private func clearPressedButton() {
        if let btn = buttonNode(named: pressedButtonName) {
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
            scaleUp.timingMode = .easeOut; fadeIn.timingMode = .easeOut
            btn.run(SKAction.group([scaleUp, fadeIn]), withKey: "pressFeedback")
        }
        pressedButtonName = nil
    }

    private func buttonNode(named name: String?) -> SKNode? {
        if name == NodeName.replay { return replayButton }
        if name == NodeName.mainMenu { return menuButton }
        return nil
    }

    private func triggerAction(isReplay: Bool) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif

        isInteractionEnabled = false
        
        if let btn = buttonNode(named: pressedButtonName) {
            let shrink = SKAction.scale(to: 0.0, duration: 0.25)
            shrink.timingMode = .easeIn
            btn.run(shrink)
        }

        let fadeAlpha = SKAction.fadeAlpha(to: 0, duration: 0.4)
        let present = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // REPLACE THIS WITH YOUR ACTUAL SCENES
            let scene = SKScene(size: self.size)
            scene.backgroundColor = self.palette.background
            scene.scaleMode = .resizeFill
            self.view?.presentScene(scene, transition: .crossFade(withDuration: 0.6))
        }
        
        let seq = SKAction.sequence([SKAction.wait(forDuration: 0.15), fadeAlpha, present])
        self.run(seq)
    }
}

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
struct ToBeContinuedScene_Previews: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: {
            let scene = ToBeContinuedScene(size: CGSize(width: 393, height: 852))
            scene.scaleMode = .resizeFill
            return scene
        }())
        .ignoresSafeArea()
    }
}
#endif
