import SpriteKit

final class PlayerNode: SKShapeNode {
    let radius: CGFloat
    let character: MemoryCharacter

    // Each 256-point tile contains a 6x6 micro grid. The player's diameter is
    // one eighth of a single micro-grid cell: 256 / 6 / 8 = 5.33 points.
    init(radius: CGFloat = 256 / 6 / 8) {
        self.radius = radius
        self.character = MemoryCharacter(
            title: "Arthur",
            color: SKColor(red: 0.49, green: 0.59, blue: 0.35, alpha: 1)
        )
        super.init()

        // Transparent shape for collision boundary
        path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        fillColor = .clear
        strokeColor = .clear
        lineWidth = 0
        zPosition = 100
        name = "PlayerNode"

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.restitution = 0
        body.friction = 0
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.worldBoundary | PhysicsCategory.building
        body.contactTestBitMask = 0
        physicsBody = body

        // Attach Arthur's Carto paper-cutout visual representation
        character.position = .zero
        character.setScale(0.7)
        character.showsNameTag = false
        addChild(character)
    }

    func applyMovement(dx: CGFloat, dy: CGFloat, dt: CGFloat) {
        character.applyMovement(dx: dx, dy: dy, dt: dt)
    }

    func celebrate() {
        character.celebrate()
    }

    func wave() {
        character.wave()
    }

    func setHoldingBook(visible: Bool) {
        character.setHoldingBook(visible: visible)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}
