import SpriteKit
import UIKit

final class QuestTrackerNode: SKShapeNode {
    private static let panelWidth: CGFloat = 252
    private var panelRect = CGRect(x: -126, y: -47, width: 252, height: 94)

    static func panelHeight(for itemCount: Int) -> CGFloat {
        switch itemCount {
        case 0: return 0
        case 1: return 94
        case 2: return 124
        default: return 164
        }
    }

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

    func update(with items: [MapQuestItem], showsItemIcon: Bool = true) {
        removeAllChildren()
        isHidden = items.isEmpty

        let visibleItems = Array(items.prefix(3))
        guard let firstItem = visibleItems.first else { return }

        let panelHeight = Self.panelHeight(for: visibleItems.count)
        panelRect = CGRect(
            x: -Self.panelWidth / 2,
            y: -panelHeight / 2,
            width: Self.panelWidth,
            height: panelHeight
        )
        path = CGPath(
            roundedRect: panelRect,
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )

        let heading = SKLabelNode(fontNamed: GameFont.name)
        heading.text = "\(firstItem.category.uppercased())  BUILD REQUIREMENTS"
        heading.fontSize = 12.5
        heading.fontColor = SKColor(red: 1.0, green: 0.81, blue: 0.38, alpha: 1)
        heading.horizontalAlignmentMode = .left
        heading.verticalAlignmentMode = .center
        heading.position = CGPoint(x: -114, y: panelHeight / 2 - 18)
        addChild(heading)

        for (index, item) in visibleItems.enumerated() {
            let row = makeRequirementRow(for: item, showsItemIcon: showsItemIcon)
            row.position = CGPoint(x: 0, y: panelHeight / 2 - 46 - CGFloat(index) * 42)
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

    private func makeRequirementRow(for item: MapQuestItem, showsItemIcon: Bool) -> SKNode {
        let root = SKNode()

        let rowBackground = SKShapeNode(rectOf: CGSize(width: 232, height: 38), cornerRadius: 10)
        rowBackground.fillColor = item.isCompleted
            ? SKColor(red: 0.17, green: 0.31, blue: 0.20, alpha: 0.90)
            : SKColor.white.withAlphaComponent(0.075)
        rowBackground.strokeColor = item.isCompleted
            ? SKColor(red: 0.37, green: 0.76, blue: 0.44, alpha: 0.72)
            : SKColor.white.withAlphaComponent(0.10)
        rowBackground.lineWidth = 1
        root.addChild(rowBackground)

        if showsItemIcon {
            let plate = SKShapeNode(rectOf: CGSize(width: 32, height: 32), cornerRadius: 7)
            plate.position = CGPoint(x: -98, y: 0)
            plate.fillColor = SKColor(red: 0.95, green: 0.89, blue: 0.74, alpha: 0.98)
            plate.strokeColor = SKColor(red: 0.50, green: 0.36, blue: 0.18, alpha: 0.45)
            plate.lineWidth = 1
            root.addChild(plate)

            if let kind = item.buildingKind,
               let assetName = BuildingObjectRenderer.assetName(for: kind) {
                let texture = SKTexture(imageNamed: assetName)
                let textureSize = texture.size()
                let scale = min(27 / max(textureSize.width, 1), 27 / max(textureSize.height, 1))
                let sprite = SKSpriteNode(texture: texture)
                sprite.size = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
                sprite.zPosition = 2
                plate.addChild(sprite)
            }
        }

        let title = SKLabelNode(fontNamed: GameFont.name)
        title.text = item.title
        title.fontSize = showsItemIcon ? 13.5 : 16
        title.fontColor = item.isCompleted ? SKColor.white.withAlphaComponent(0.74) : .white
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.numberOfLines = 2
        title.preferredMaxLayoutWidth = showsItemIcon ? 184 : 220
        title.lineBreakMode = .byWordWrapping
        title.position = CGPoint(x: showsItemIcon ? -76 : -110, y: 0)
        root.addChild(title)

        return root
    }
}
