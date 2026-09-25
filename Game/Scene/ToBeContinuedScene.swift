import SpriteKit

final class ToBeContinuedScene: SKScene {
    private enum NodeName {
        static let replay = "EndingReplay"
        static let mainMenu = "EndingMainMenu"
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.015, green: 0.035, blue: 0.06, alpha: 1)
        scaleMode = .resizeFill

        let eyebrow = SKLabelNode(fontNamed: "AvenirNext-Medium")
        eyebrow.text = "ARTHUR'S JOURNEY"
        eyebrow.fontSize = 13
        eyebrow.fontColor = SKColor.white.withAlphaComponent(0.48)
        eyebrow.position = CGPoint(x: size.width / 2, y: size.height * 0.69)
        addChild(eyebrow)

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "TO BE CONTINUED"
        title.fontSize = 34
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.61)
        addChild(title)

        let divider = SKShapeNode(rectOf: CGSize(width: 84, height: 3), cornerRadius: 1.5)
        divider.fillColor = SKColor(red: 0.95, green: 0.72, blue: 0.20, alpha: 1)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: size.width / 2, y: title.position.y - 42)
        addChild(divider)

        addChild(makeButton(title: "ULANGI", name: NodeName.replay, y: size.height * 0.37, primary: true))
        addChild(makeButton(title: "MAIN MENU", name: NodeName.mainMenu, y: size.height * 0.27, primary: false))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let stack = nodes(at: location)
        if stack.contains(where: { $0.name == NodeName.replay }) {
            resetGameProgress()
            let scene = GameScene(size: size)
            scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.4))
        } else if stack.contains(where: { $0.name == NodeName.mainMenu }) {
            let scene = MainMenuScene(size: size)
            scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.4))
        }
    }

    private func resetGameProgress() {
        try? SaveGameService().deleteSave()
        VillageQuest1Controller().reset()
        VillageQuest2Controller().reset()
        VillageQuest3Controller().reset()
        VillageQuest4Controller().reset()
        VillageQuest5Controller().reset()
        VillageQuest6Controller().reset()
    }

    private func makeButton(title: String, name: String, y: CGFloat, primary: Bool) -> SKNode {
        let root = SKNode()
        root.name = name
        root.position = CGPoint(x: size.width / 2, y: y)

        let background = SKShapeNode(rectOf: CGSize(width: 230, height: 58), cornerRadius: 17)
        background.name = name
        background.fillColor = primary
            ? SKColor(red: 0.95, green: 0.72, blue: 0.20, alpha: 1)
            : SKColor.white.withAlphaComponent(0.06)
        background.strokeColor = primary ? .white : SKColor.white.withAlphaComponent(0.46)
        background.lineWidth = 2
        root.addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = name
        label.text = title
        label.fontSize = 17
        label.fontColor = primary
            ? SKColor(red: 0.05, green: 0.10, blue: 0.13, alpha: 1)
            : .white
        label.verticalAlignmentMode = .center
        root.addChild(label)
        return root
    }
}
