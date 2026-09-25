import SpriteKit

enum CameraMode: Equatable {
    case followPlayer
    case transitioningToMap
    case mapOverview(center: CGPoint)
    case transitioningToWorld
}

final class CameraController {
    private let cameraNode: SKCameraNode
    private let smoothing: CGFloat

    var mode: CameraMode = .followPlayer

    init(cameraNode: SKCameraNode, smoothing: CGFloat = 0.14) {
        self.cameraNode = cameraNode
        self.smoothing = smoothing
    }

    var currentScale: CGFloat {
        cameraNode.xScale
    }

    func update(targetPosition: CGPoint) {
        let desiredPosition: CGPoint
        switch mode {
        case .followPlayer:
            desiredPosition = targetPosition
        case .mapOverview(let center):
            desiredPosition = center
        case .transitioningToMap, .transitioningToWorld:
            return
        }

        cameraNode.position = CGPoint(
            x: cameraNode.position.x + (desiredPosition.x - cameraNode.position.x) * smoothing,
            y: cameraNode.position.y + (desiredPosition.y - cameraNode.position.y) * smoothing
        )
    }

    func applyTransitionFrame(position: CGPoint, scale: CGFloat) {
        cameraNode.position = position
        cameraNode.setScale(scale)
    }

    func beginTransitionToMap() {
        mode = .transitioningToMap
    }

    func beginTransitionToWorld() {
        mode = .transitioningToWorld
    }

    func setMapOverview(center: CGPoint) {
        mode = .mapOverview(center: center)
    }

    func snapToMapOverview(center: CGPoint) {
        mode = .mapOverview(center: center)
        cameraNode.position = center
        cameraNode.setScale(1.35)
    }

    func returnToPlayerFollow() {
        mode = .followPlayer
        cameraNode.setScale(1.0)
    }
}
