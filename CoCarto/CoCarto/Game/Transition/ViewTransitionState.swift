import CoreGraphics

enum ViewTransitionState: Equatable, Sendable {
    case idleWorld
    case worldToMap(progress: CGFloat)
    case idleMap
    case mapToWorld(progress: CGFloat)

    var isTransitioning: Bool {
        switch self {
        case .worldToMap, .mapToWorld:
            return true
        case .idleWorld, .idleMap:
            return false
        }
    }

    var normalizedProgress: CGFloat {
        switch self {
        case .idleWorld:
            return 0
        case .worldToMap(let progress), .mapToWorld(let progress):
            return progress
        case .idleMap:
            return 1
        }
    }
}
