import CoreGraphics
import Foundation

struct MapWorldTransitionFrame: Equatable, Sendable {
    let cameraPosition: CGPoint
    let cameraScale: CGFloat
    let worldAlpha: CGFloat
    let mapAlpha: CGFloat
    let playerAlpha: CGFloat
    let enterMapButtonAlpha: CGFloat
}

final class MapWorldTransitionController {
    private let config: MapWorldTransitionConfig
    private(set) var state: ViewTransitionState = .idleWorld

    private var elapsedTime: TimeInterval = 0
    private var duration: TimeInterval = 0
    private var startCameraPosition: CGPoint = .zero
    private var targetCameraPosition: CGPoint = .zero
    private var startCameraScale: CGFloat = 1
    private var targetCameraScale: CGFloat = 1
    private var activeDirection: Direction = .toMap

    init(config: MapWorldTransitionConfig = .standard) {
        self.config = config
    }

    var canUseWorldInput: Bool {
        state == .idleWorld
    }

    var canUseMapInput: Bool {
        state == .idleMap
    }

    func presentMapImmediately(at cameraPosition: CGPoint) {
        elapsedTime = 0
        duration = 0
        startCameraPosition = cameraPosition
        targetCameraPosition = cameraPosition
        startCameraScale = config.mapCameraScale
        targetCameraScale = config.mapCameraScale
        activeDirection = .toMap
        state = .idleMap
    }

    @discardableResult
    func beginWorldToMap(
        from cameraPosition: CGPoint,
        cameraScale: CGFloat,
        to mapCenter: CGPoint
    ) -> Bool {
        guard state == .idleWorld else {
            return false
        }

        start(
            direction: .toMap,
            duration: config.enterDuration,
            startCameraPosition: cameraPosition,
            targetCameraPosition: mapCenter,
            startCameraScale: cameraScale,
            targetCameraScale: config.mapCameraScale
        )
        return true
    }

    @discardableResult
    func beginMapToWorld(
        from cameraPosition: CGPoint,
        cameraScale: CGFloat,
        to worldTarget: CGPoint
    ) -> Bool {
        guard state == .idleMap else {
            return false
        }

        start(
            direction: .toWorld,
            duration: config.exitDuration,
            startCameraPosition: cameraPosition,
            targetCameraPosition: worldTarget,
            startCameraScale: cameraScale,
            targetCameraScale: config.worldCameraScale
        )
        return true
    }

    func update(deltaTime: TimeInterval) -> MapWorldTransitionFrame? {
        guard state.isTransitioning, duration > 0 else {
            return nil
        }

        elapsedTime = min(duration, elapsedTime + max(0, deltaTime))
        let rawProgress = CGFloat(elapsedTime / duration)
        let easedProgress = Self.smoothstep(rawProgress)
        state = activeDirection == .toMap ? .worldToMap(progress: rawProgress) : .mapToWorld(progress: rawProgress)

        let frame = makeFrame(easedProgress: easedProgress)
        if elapsedTime >= duration {
            state = activeDirection == .toMap ? .idleMap : .idleWorld
        }
        return frame
    }

    func restingFrame() -> MapWorldTransitionFrame {
        switch state {
        case .idleWorld:
            return MapWorldTransitionFrame(
                cameraPosition: targetCameraPosition,
                cameraScale: config.worldCameraScale,
                worldAlpha: 1,
                mapAlpha: 0,
                playerAlpha: 1,
                enterMapButtonAlpha: 1
            )
        case .idleMap:
            return MapWorldTransitionFrame(
                cameraPosition: targetCameraPosition,
                cameraScale: config.mapCameraScale,
                worldAlpha: 0.08,
                mapAlpha: 1,
                playerAlpha: 0,
                enterMapButtonAlpha: 0
            )
        case .worldToMap, .mapToWorld:
            return makeFrame(easedProgress: Self.smoothstep(state.normalizedProgress))
        }
    }

    private func start(
        direction: Direction,
        duration: TimeInterval,
        startCameraPosition: CGPoint,
        targetCameraPosition: CGPoint,
        startCameraScale: CGFloat,
        targetCameraScale: CGFloat
    ) {
        activeDirection = direction
        elapsedTime = 0
        self.duration = duration
        self.startCameraPosition = startCameraPosition
        self.targetCameraPosition = targetCameraPosition
        self.startCameraScale = startCameraScale
        self.targetCameraScale = targetCameraScale
        state = direction == .toMap ? .worldToMap(progress: 0) : .mapToWorld(progress: 0)
    }

    private func makeFrame(easedProgress: CGFloat) -> MapWorldTransitionFrame {
        let semanticProgress = activeDirection == .toMap ? easedProgress : 1 - easedProgress
        return MapWorldTransitionFrame(
            cameraPosition: startCameraPosition.interpolated(to: targetCameraPosition, progress: easedProgress),
            cameraScale: startCameraScale + (targetCameraScale - startCameraScale) * easedProgress,
            worldAlpha: Self.inverseRamp(semanticProgress, start: config.worldFadeStart),
            mapAlpha: Self.ramp(semanticProgress, start: config.mapFadeStart),
            playerAlpha: Self.inverseRamp(semanticProgress, start: config.playerFadeStart),
            enterMapButtonAlpha: Self.inverseRamp(semanticProgress, start: 0.05)
        )
    }

    private static func smoothstep(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        return t * t * (3 - 2 * t)
    }

    private static func ramp(_ value: CGFloat, start: CGFloat) -> CGFloat {
        guard start < 1 else {
            return value >= 1 ? 1 : 0
        }
        return min(max((value - start) / (1 - start), 0), 1)
    }

    private static func inverseRamp(_ value: CGFloat, start: CGFloat) -> CGFloat {
        1 - ramp(value, start: start)
    }

    private enum Direction {
        case toMap
        case toWorld
    }
}

private extension CGPoint {
    func interpolated(to target: CGPoint, progress: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (target.x - x) * progress,
            y: y + (target.y - y) * progress
        )
    }
}
