import CoreGraphics
import Foundation

struct MapViewportConfiguration: Equatable, Sendable {
    let padding: CGFloat
    let autoPanEdgeWidth: CGFloat
    let minimumAutoPanSpeed: CGFloat
    let maximumAutoPanSpeed: CGFloat

    static let standard = MapViewportConfiguration(
        padding: 220,
        autoPanEdgeWidth: 92,
        minimumAutoPanSpeed: 80,
        maximumAutoPanSpeed: 520
    )
}

struct MapViewportController: Sendable {
    private(set) var contentOffset: CGPoint = .zero
    private var minOffset: CGPoint = .zero
    private var maxOffset: CGPoint = .zero
    private let configuration: MapViewportConfiguration

    init(configuration: MapViewportConfiguration = .standard) {
        self.configuration = configuration
    }

    mutating func reset(contentBounds: CGRect, sceneSize: CGSize, focusPoint: CGPoint) {
        recalculateBounds(contentBounds: contentBounds, sceneSize: sceneSize)
        contentOffset = CGPoint(x: -focusPoint.x, y: -focusPoint.y)
    }

    mutating func recalculateBounds(contentBounds: CGRect, sceneSize: CGSize) {
        let halfWidth = sceneSize.width / 2
        let halfHeight = sceneSize.height / 2
        minOffset = CGPoint(
            x: halfWidth - contentBounds.maxX - configuration.padding,
            y: halfHeight - contentBounds.maxY - configuration.padding
        )
        maxOffset = CGPoint(
            x: -halfWidth - contentBounds.minX + configuration.padding,
            y: -halfHeight - contentBounds.minY + configuration.padding
        )

        if minOffset.x > maxOffset.x {
            let midpoint = (minOffset.x + maxOffset.x) / 2
            minOffset.x = midpoint
            maxOffset.x = midpoint
        }
        if minOffset.y > maxOffset.y {
            let midpoint = (minOffset.y + maxOffset.y) / 2
            minOffset.y = midpoint
            maxOffset.y = midpoint
        }
    }

    mutating func pan(by delta: CGPoint) -> CGPoint {
        contentOffset = CGPoint(x: contentOffset.x + delta.x, y: contentOffset.y + delta.y)
        return contentOffset
    }

    mutating func setContentOffset(_ offset: CGPoint) -> CGPoint {
        contentOffset = offset
        return contentOffset
    }

    mutating func autoPanVelocity(for screenPosition: CGPoint, sceneSize: CGSize) -> CGPoint {
        let halfWidth = sceneSize.width / 2
        let halfHeight = sceneSize.height / 2
        let edge = configuration.autoPanEdgeWidth
        var velocity = CGPoint.zero

        let leftDepth = max(0, (screenPosition.x - (-halfWidth + edge)) * -1 / edge)
        let rightDepth = max(0, (screenPosition.x - (halfWidth - edge)) / edge)
        let bottomDepth = max(0, (screenPosition.y - (-halfHeight + edge)) * -1 / edge)
        let topDepth = max(0, (screenPosition.y - (halfHeight - edge)) / edge)

        if leftDepth > 0 {
            velocity.x = speed(for: leftDepth)
        } else if rightDepth > 0 {
            velocity.x = -speed(for: rightDepth)
        }

        if bottomDepth > 0 {
            velocity.y = speed(for: bottomDepth)
        } else if topDepth > 0 {
            velocity.y = -speed(for: topDepth)
        }

        return velocity
    }

    mutating func autoPan(screenPosition: CGPoint, sceneSize: CGSize, deltaTime: TimeInterval) -> CGPoint {
        let velocity = autoPanVelocity(for: screenPosition, sceneSize: sceneSize)
        let delta = CGPoint(x: velocity.x * deltaTime, y: velocity.y * deltaTime)
        return pan(by: delta)
    }

    func screenPointToContent(_ screenPoint: CGPoint) -> CGPoint {
        CGPoint(x: screenPoint.x - contentOffset.x, y: screenPoint.y - contentOffset.y)
    }

    func contentPointToScreen(_ contentPoint: CGPoint) -> CGPoint {
        CGPoint(x: contentPoint.x + contentOffset.x, y: contentPoint.y + contentOffset.y)
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, minOffset.x), maxOffset.x),
            y: min(max(point.y, minOffset.y), maxOffset.y)
        )
    }

    private func speed(for depth: CGFloat) -> CGFloat {
        let normalized = min(max(depth, 0), 1)
        return configuration.minimumAutoPanSpeed + normalized * (configuration.maximumAutoPanSpeed - configuration.minimumAutoPanSpeed)
    }
}
