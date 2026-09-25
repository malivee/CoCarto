import SpriteKit

final class LandmarkNode: SKNode {
    let landmarkID: LandmarkID

    private let marker = SKShapeNode(circleOfRadius: 36)
    private let label = SKLabelNode(fontNamed: "Menlo-Bold")

    init(landmark: WorldLandmark, position: CGPoint) {
        landmarkID = landmark.id
        super.init()
        name = "LandmarkNode-\(landmark.id.rawValue)"
        zPosition = 80

        marker.lineWidth = 5
        addChild(marker)

        label.fontSize = 18
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -58)
        addChild(label)

        apply(landmark: landmark, position: position)
    }

    func apply(landmark: WorldLandmark, position: CGPoint) {
        self.position = position
        label.text = landmark.id.debugLabel

        switch landmark.state {
        case .inactive:
            alpha = 0.55
            marker.fillColor = SKColor.black.withAlphaComponent(0.2)
            marker.strokeColor = SKColor.gray.withAlphaComponent(0.9)
            label.fontColor = .gray
        case .active:
            alpha = 1
            marker.fillColor = SKColor.systemCyan.withAlphaComponent(0.38)
            marker.strokeColor = .systemCyan
            label.fontColor = .systemCyan
        case .consumed:
            alpha = 0.35
            marker.fillColor = SKColor.systemGreen.withAlphaComponent(0.2)
            marker.strokeColor = .systemGreen
            label.fontColor = .systemGreen
        }
    }

    func playActivationPulse() {
        removeAction(forKey: "activationPulse")
        let pulse = SKAction.sequence([
            .scale(to: 1.35, duration: 0.18),
            .scale(to: 1.0, duration: 0.22),
            .scale(to: 1.22, duration: 0.16),
            .scale(to: 1.0, duration: 0.18)
        ])
        run(pulse, withKey: "activationPulse")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}

private extension LandmarkID {
    var debugLabel: String {
        switch self {
        case .outerExit:
            return "EXIT"
        }
    }
}
