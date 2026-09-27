import SpriteKit
import UIKit

final class QuestTrackerNode: SKShapeNode {
    override init() {
        super.init()
        path = CGPath(
            roundedRect: CGRect(x: -126, y: -56, width: 252, height: 112),
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )
        fillColor = SKColor.black.withAlphaComponent(0.34)
        strokeColor = SKColor.white.withAlphaComponent(0.10)
        lineWidth = 1
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func update(with items: [MapQuestItem]) {
        removeAllChildren()
        isHidden = items.isEmpty

        let visibleItems = Array(items.prefix(2))
        for (index, item) in visibleItems.enumerated() {
            let node = makeRequirementNode(for: item)
            node.position = CGPoint(
                x: visibleItems.count == 1 ? 0 : (index == 0 ? -60 : 60),
                y: 0
            )
            addChild(node)
        }
    }

    func setTutorialHighlighted(_ isHighlighted: Bool) {
        childNode(withName: "TutorialGlow")?.removeFromParent()
        guard isHighlighted else { return }

        let glow = SKShapeNode(
            rect: CGRect(x: -132, y: -62, width: 264, height: 124),
            cornerRadius: 20
        )
        glow.name = "TutorialGlow"
        glow.fillColor = SKColor.clear
        glow.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.24, alpha: 1.0)
        glow.lineWidth = 3
        glow.glowWidth = 5
        glow.zPosition = 50
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.38, duration: 0.65),
            SKAction.fadeAlpha(to: 1.0, duration: 0.65)
        ])))
        addChild(glow)
    }

    private func makeRequirementNode(for item: MapQuestItem) -> SKNode {
        let root = SKNode()
        root.alpha = item.isCompleted ? 0.45 : 1

        let categoryLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        categoryLabel.text = item.category.uppercased()
        categoryLabel.fontSize = 10.5
        categoryLabel.fontColor = SKColor.white.withAlphaComponent(0.78)
        categoryLabel.verticalAlignmentMode = .center
        categoryLabel.horizontalAlignmentMode = .center
        categoryLabel.position = CGPoint(x: 0, y: 38)
        root.addChild(categoryLabel)

        let plate = SKShapeNode(rectOf: CGSize(width: 62, height: 62), cornerRadius: 12)
        plate.fillColor = SKColor(red: 0.95, green: 0.89, blue: 0.74, alpha: 0.96)
        plate.strokeColor = item.isCompleted
            ? SKColor(red: 0.45, green: 0.95, blue: 0.56, alpha: 0.95)
            : SKColor(red: 0.94, green: 0.68, blue: 0.19, alpha: 0.82)
        plate.lineWidth = item.isCompleted ? 2.4 : 1.5
        root.addChild(plate)

        if let kind = item.buildingKind,
           let assetName = BuildingObjectRenderer.assetName(for: kind) {
            let texture = SKTexture(imageNamed: assetName)
            let textureSize = texture.size()
            let maximumSize = CGSize(width: 52, height: 52)
            let scale = min(
                maximumSize.width / max(textureSize.width, 1),
                maximumSize.height / max(textureSize.height, 1)
            )
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
            sprite.zPosition = 2
            plate.addChild(sprite)
        } else {
            let fallbackLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            fallbackLabel.text = item.title
            fallbackLabel.fontSize = 10.5
            fallbackLabel.fontColor = SKColor(red: 0.23, green: 0.16, blue: 0.10, alpha: 1)
            fallbackLabel.numberOfLines = 3
            fallbackLabel.preferredMaxLayoutWidth = 54
            fallbackLabel.lineBreakMode = .byWordWrapping
            fallbackLabel.verticalAlignmentMode = .center
            fallbackLabel.horizontalAlignmentMode = .center
            fallbackLabel.zPosition = 2
            plate.addChild(fallbackLabel)
        }

        if item.isCompleted {
            let checkBackground = SKShapeNode(circleOfRadius: 12)
            checkBackground.position = CGPoint(x: 24, y: -24)
            checkBackground.fillColor = SKColor(red: 0.18, green: 0.64, blue: 0.28, alpha: 1)
            checkBackground.strokeColor = SKColor.white.withAlphaComponent(0.9)
            checkBackground.lineWidth = 1.2
            checkBackground.zPosition = 4
            let check = SKLabelNode(fontNamed: "AvenirNext-Bold")
            check.text = "✓"
            check.fontSize = 15
            check.fontColor = .white
            check.verticalAlignmentMode = .center
            check.horizontalAlignmentMode = .center
            check.position.y = -1
            checkBackground.addChild(check)
            root.addChild(checkBackground)
        }

        return root
    }
}
