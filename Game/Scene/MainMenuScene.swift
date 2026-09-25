import SpriteKit

final class MainMenuScene: SKScene {
    private enum NodeName {
        static let play = "MainMenuPlay"
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.025, green: 0.08, blue: 0.13, alpha: 1)
        scaleMode = .resizeFill

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "COCARTO"
        title.fontSize = 48
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.63)
        addChild(title)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = "Shape the land. Follow the story."
        subtitle.fontSize = 15
        subtitle.fontColor = SKColor.white.withAlphaComponent(0.62)
        subtitle.position = CGPoint(x: size.width / 2, y: title.position.y - 48)
        addChild(subtitle)

        addChild(makeButton(title: "PLAY", name: NodeName.play, y: size.height * 0.35))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self),
              nodes(at: location).contains(where: { $0.name == NodeName.play }) else { return }
        let scene = GameScene(size: size)
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: .fade(withDuration: 0.35))
    }

    private func makeButton(title: String, name: String, y: CGFloat) -> SKNode {
        let root = SKNode()
        root.name = name
        root.position = CGPoint(x: size.width / 2, y: y)

        let background = SKShapeNode(rectOf: CGSize(width: 220, height: 60), cornerRadius: 18)
        background.name = name
        background.fillColor = SKColor(red: 0.95, green: 0.72, blue: 0.20, alpha: 1)
        background.strokeColor = .white
        background.lineWidth = 2
        root.addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = name
        label.text = title
        label.fontSize = 18
        label.fontColor = SKColor(red: 0.05, green: 0.10, blue: 0.13, alpha: 1)
        label.verticalAlignmentMode = .center
        root.addChild(label)
        return root
    }
}
