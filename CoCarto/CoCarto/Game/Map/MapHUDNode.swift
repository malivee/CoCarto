import SpriteKit

final class MapHUDNode: SKNode {
    private let rotateButton = MapButtonNode(title: "ROTATE ↻", name: MapNodeName.rotateButton.rawValue)
    private let cancelButton = MapButtonNode(title: "CANCEL", name: MapNodeName.cancelButton.rawValue)
    private let confirmButton = MapButtonNode(title: "CONFIRM", name: MapNodeName.confirmButton.rawValue)
    private let exitButton = MapButtonNode(title: "EXIT", name: MapNodeName.exitButton.rawValue)
    private let footprint3Button = MapButtonNode(title: "SHOW 3x3", name: MapNodeName.footprint3Button.rawValue)
    private let footprint6Button = MapButtonNode(title: "SHOW 6x6", name: MapNodeName.footprint6Button.rawValue)
    private let footprint69Button = MapButtonNode(title: "SHOW 6x9", name: MapNodeName.footprint69Button.rawValue)
    private let footprint915Button = MapButtonNode(title: "SHOW 9x15", name: MapNodeName.footprint915Button.rawValue)
    private let statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    override init() {
        super.init()
        zPosition = 600
        addChild(rotateButton)
        addChild(cancelButton)
        addChild(confirmButton)
        addChild(exitButton)
        addChild(footprint3Button)
        addChild(footprint6Button)
        addChild(footprint69Button)
        addChild(footprint915Button)

        statusLabel.fontSize = 17
        statusLabel.fontColor = .white
        statusLabel.horizontalAlignmentMode = .right
        statusLabel.verticalAlignmentMode = .bottom
        statusLabel.numberOfLines = 0
        addChild(statusLabel)
    }

    func layout(cameraCenter: CGPoint, sceneSize: CGSize, preview: PiecePlacementPreview?, puzzleStatusText: String) {
        let right = cameraCenter.x + sceneSize.width * 0.40
        let bottom = cameraCenter.y - sceneSize.height * 0.34
        let spacing: CGFloat = 116

        rotateButton.position = CGPoint(x: right - spacing * 3, y: bottom)
        cancelButton.position = CGPoint(x: right - spacing * 2, y: bottom)
        confirmButton.position = CGPoint(x: right - spacing, y: bottom)
        exitButton.position = CGPoint(x: right, y: bottom)
        statusLabel.position = CGPoint(x: right, y: bottom + 112)
        footprint3Button.position = CGPoint(x: right - spacing * 3, y: bottom + 58)
        footprint6Button.position = CGPoint(x: right - spacing * 2, y: bottom + 58)
        footprint69Button.position = CGPoint(x: right - spacing, y: bottom + 58)
        footprint915Button.position = CGPoint(x: right, y: bottom + 58)

        let canConfirm = preview?.isValid == true
        confirmButton.setEnabled(canConfirm)
        rotateButton.setEnabled(preview != nil)
        cancelButton.setEnabled(preview != nil)

        if let preview {
            statusLabel.text = "\(puzzleStatusText)\norigin \(preview.proposedPosition.x),\(preview.proposedPosition.y)\nrot \(preview.proposedRotation.rawValue)  \(preview.isValid ? "valid" : "invalid")"
        } else {
            statusLabel.text = "\(puzzleStatusText)\ntap movable piece"
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}

final class MapButtonNode: SKNode {
    private let background: SKShapeNode
    private let label: SKLabelNode

    init(title: String, name: String) {
        let buttonWidth = max(CGFloat(title.count) * 12 + 28, 64)
        background = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: 48), cornerRadius: 8)
        label = SKLabelNode(fontNamed: "Menlo-Bold")
        super.init()
        self.name = name
        isUserInteractionEnabled = false

        background.fillColor = SKColor.black.withAlphaComponent(0.68)
        background.strokeColor = .white
        background.lineWidth = 3
        addChild(background)

        label.text = title
        label.fontSize = 17
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
    }

    func setEnabled(_ isEnabled: Bool) {
        alpha = isEnabled ? 1 : 0.35
        background.strokeColor = isEnabled ? .white : .gray
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}
