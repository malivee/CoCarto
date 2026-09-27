import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

/// A compact, reusable first-screen tutorial for SpriteKit minigames.
public final class MinigameTutorialOverlayNode: SKNode {
    public var onDismiss: (() -> Void)?

    public init(title: String, steps: [String]) {
        super.init()
        isUserInteractionEnabled = true
        zPosition = 10_000

        let dimmer = SKShapeNode(rectOf: CGSize(width: 5_000, height: 5_000))
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.72)
        dimmer.strokeColor = .clear
        dimmer.zPosition = -1
        addChild(dimmer)

        let height = CGFloat(142 + steps.count * 34)
        let card = SKShapeNode(rectOf: CGSize(width: 332, height: height), cornerRadius: 22)
        card.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.07, alpha: 0.98)
        card.strokeColor = SKColor(red: 0.92, green: 0.73, blue: 0.35, alpha: 1)
        card.lineWidth = 2
        addChild(card)

        let heading = SKLabelNode(fontNamed: "AvenirNext-Bold")
        heading.text = title.uppercased()
        heading.fontSize = 19
        heading.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.58, alpha: 1)
        heading.verticalAlignmentMode = .center
        heading.position.y = height / 2 - 38
        addChild(heading)

        for (index, step) in steps.enumerated() {
            let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
            label.text = "\(index + 1).  \(step)"
            label.fontSize = 13
            label.fontColor = .white
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: -138, y: height / 2 - 78 - CGFloat(index * 34))
            addChild(label)
        }

        let prompt = SKLabelNode(fontNamed: "AvenirNext-Bold")
        prompt.text = "TAP TO START"
        prompt.fontSize = 14
        prompt.fontColor = SKColor(red: 0.55, green: 0.95, blue: 0.65, alpha: 1)
        prompt.verticalAlignmentMode = .center
        prompt.position.y = -height / 2 + 34
        addChild(prompt)

        prompt.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.45, duration: 0.65),
            .fadeAlpha(to: 1.0, duration: 0.65)
        ])))
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func dismiss() {
        isUserInteractionEnabled = false
        run(.sequence([
            .group([
                .fadeOut(withDuration: 0.18),
                .scale(to: 0.96, duration: 0.18)
            ]),
            .run { [weak self] in self?.onDismiss?() },
            .removeFromParent()
        ]))
    }

    #if canImport(UIKit)
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }
    #endif
}
