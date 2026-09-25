import CoreGraphics

final class InputController {
    private let deadZone: CGFloat
    private var targetWorldPosition: CGPoint?

    init(deadZone: CGFloat = 18) {
        self.deadZone = deadZone
    }

    var movementVector: CGVector {
        guard let playerPosition, let targetWorldPosition else {
            return .zero
        }

        let dx = targetWorldPosition.x - playerPosition.x
        let dy = targetWorldPosition.y - playerPosition.y
        let distance = hypot(dx, dy)

        guard distance > deadZone else {
            return .zero
        }

        return CGVector(dx: dx / distance, dy: dy / distance)
    }

    var playerPosition: CGPoint?

    func beginTouch(at worldPosition: CGPoint) {
        targetWorldPosition = worldPosition
    }

    func moveTouch(to worldPosition: CGPoint) {
        targetWorldPosition = worldPosition
    }

    func endTouch() {
        targetWorldPosition = nil
    }
}
