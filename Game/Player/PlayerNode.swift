import SpriteKit

final class PlayerNode: SKShapeNode {
    let radius: CGFloat

    // Each 256-point tile contains a 6x6 micro grid. The player's diameter is
    // one eighth of a single micro-grid cell: 256 / 6 / 8 = 5.33 points.
    init(radius: CGFloat = 256 / 6 / 8) {
        self.radius = radius
        super.init()

        path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        fillColor = SKColor(red: 0.95, green: 0.92, blue: 0.78, alpha: 1)
        strokeColor = .black
        lineWidth = 0.75
        zPosition = 100
        name = "PlayerNode"

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.restitution = 0
        body.friction = 0
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.worldBoundary
        body.contactTestBitMask = 0
        physicsBody = body
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}
