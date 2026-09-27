import SpriteKit
import UIKit

final class QuestTrackerNode: SKShapeNode {
    private var panelRect = CGRect(x: -143, y: -69, width: 286, height: 138)

    override init() {
        super.init()
        path = CGPath(
            roundedRect: panelRect,
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )
        fillColor = SKColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 0.88)
        strokeColor = SKColor.white.withAlphaComponent(0.16)
        lineWidth = 1
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func update(with items: [MapQuestItem]) {
        removeAllChildren()
        isHidden = items.isEmpty

        let visibleItems = Array(items.prefix(3))
        guard let firstItem = visibleItems.first else { return }

        let panelHeight: CGFloat = visibleItems.count >= 3 ? 184 : 138
        panelRect = CGRect(x: -143, y: -panelHeight / 2, width: 286, height: panelHeight)
        path = CGPath(
            roundedRect: panelRect,
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )

        let heading = SKLabelNode(fontNamed: "AvenirNext-Bold")
        heading.text = "\(firstItem.category.uppercased())  BUILD REQUIREMENTS"
        heading.fontSize = 11
        heading.fontColor = SKColor(red: 1.0, green: 0.81, blue: 0.38, alpha: 1)
        heading.horizontalAlignmentMode = .left
        heading.verticalAlignmentMode = .center
        heading.position = CGPoint(x: -130, y: visibleItems.count >= 3 ? 73 : 50)
        addChild(heading)

        let rowPositions: [CGFloat]
        switch visibleItems.count {
        case 1:
            rowPositions = [-5]
        case 2:
            rowPositions = [16, -35]
        default:
            rowPositions = [38, -10, -58]
        }
        for (index, item) in visibleItems.enumerated() {
            let row = makeRequirementRow(for: item)
            row.position = CGPoint(x: 0, y: rowPositions[index])
            addChild(row)
        }
    }

    func setTutorialHighlighted(_ isHighlighted: Bool) {
        childNode(withName: "TutorialGlow")?.removeFromParent()
        guard isHighlighted else { return }

        let glow = SKShapeNode(rect: panelRect.insetBy(dx: -6, dy: -6), cornerRadius: 20)
        glow.name = "TutorialGlow"
        glow.fillColor = .clear
        glow.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.24, alpha: 1.0)
        glow.lineWidth = 3
        glow.glowWidth = 5
        glow.zPosition = 50
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.38, duration: 0.65),
            .fadeAlpha(to: 1.0, duration: 0.65)
        ])))
        addChild(glow)
    }

    private func makeRequirementRow(for item: MapQuestItem) -> SKNode {
        let root = SKNode()

        let rowBackground = SKShapeNode(rectOf: CGSize(width: 264, height: 44), cornerRadius: 11)
        rowBackground.fillColor = item.isCompleted
            ? SKColor(red: 0.17, green: 0.31, blue: 0.20, alpha: 0.90)
            : SKColor.white.withAlphaComponent(0.075)
        rowBackground.strokeColor = item.isCompleted
            ? SKColor(red: 0.37, green: 0.76, blue: 0.44, alpha: 0.72)
            : SKColor.white.withAlphaComponent(0.10)
        rowBackground.lineWidth = 1
        root.addChild(rowBackground)

        let plate = SKShapeNode(rectOf: CGSize(width: 36, height: 36), cornerRadius: 8)
        plate.position = CGPoint(x: -110, y: 0)
        plate.fillColor = SKColor(red: 0.95, green: 0.89, blue: 0.74, alpha: 0.98)
        plate.strokeColor = SKColor(red: 0.50, green: 0.36, blue: 0.18, alpha: 0.45)
        plate.lineWidth = 1
        root.addChild(plate)

        if let kind = item.buildingKind,
           let assetName = BuildingObjectRenderer.assetName(for: kind) {
            let texture = SKTexture(imageNamed: assetName)
            let textureSize = texture.size()
            let scale = min(30 / max(textureSize.width, 1), 30 / max(textureSize.height, 1))
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
            sprite.zPosition = 2
            plate.addChild(sprite)
        }

        let title = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        title.text = item.title
        title.fontSize = 12
        title.fontColor = item.isCompleted ? SKColor.white.withAlphaComponent(0.74) : .white
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.numberOfLines = 2
        title.preferredMaxLayoutWidth = 205
        title.lineBreakMode = .byWordWrapping
        title.position = CGPoint(x: -84, y: 0)
        root.addChild(title)

        return root
    }
}
