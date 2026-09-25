import SpriteKit
import UIKit

final class QuestTrackerNode: SKShapeNode {
    private let questLabels = [SKLabelNode(), SKLabelNode()]

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

        for (index, label) in questLabels.enumerated() {
            label.fontName = "AvenirNext-Medium"
            label.fontSize = 13
            label.numberOfLines = 2
            label.preferredMaxLayoutWidth = 214
            label.lineBreakMode = .byWordWrapping
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: -108, y: index == 0 ? 25 : -25)
            label.zPosition = 1
            addChild(label)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func update(with items: [MapQuestItem]) {
        isHidden = items.isEmpty
        for (index, label) in questLabels.enumerated() {
            guard items.indices.contains(index) else {
                label.attributedText = nil
                label.text = nil
                continue
            }

            let item = items[index]
            label.position.y = items.count == 1 ? 0 : (index == 0 ? 25 : -25)
            let marker = item.isCompleted ? "✓" : "○"
            let text = "\(marker)  \(item.category.uppercased()) · \(item.title)"
            label.attributedText = NSAttributedString(string: text, attributes: [
                .font: UIFont(name: "AvenirNext-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13),
                .foregroundColor: item.isCompleted
                    ? UIColor.white.withAlphaComponent(0.38)
                    : UIColor.white.withAlphaComponent(0.90),
                .strikethroughStyle: item.isCompleted ? NSUnderlineStyle.single.rawValue : 0,
                .strikethroughColor: UIColor.white.withAlphaComponent(0.48)
            ])
        }
    }
}
