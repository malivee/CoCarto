import CoreGraphics

final class InputController {
    private let deadZone: CGFloat
    private let maximumDistance: CGFloat
    private var touchOrigin: CGPoint?
    private var touchPosition: CGPoint?

    init(deadZone: CGFloat = 10, maximumDistance: CGFloat = 72) {
        self.deadZone = deadZone
        self.maximumDistance = maximumDistance
    }

    var movementVector: CGVector {
        guard let touchOrigin, let touchPosition else {
            return .zero
        }

        let dx = touchPosition.x - touchOrigin.x
        let dy = touchPosition.y - touchOrigin.y
        let distance = hypot(dx, dy)

        guard distance > deadZone else {
            return .zero
        }

        let strength = min(1, (distance - deadZone) / (maximumDistance - deadZone))
        return CGVector(dx: dx / distance * strength, dy: dy / distance * strength)
    }

    var playerPosition: CGPoint?

    func beginTouch(at controlPosition: CGPoint) {
        touchOrigin = controlPosition
        touchPosition = controlPosition
    }

    func moveTouch(to controlPosition: CGPoint) {
        touchPosition = controlPosition
    }

    func endTouch() {
        touchOrigin = nil
        touchPosition = nil
    }
}
