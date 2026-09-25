import CoreGraphics
import Foundation

struct MapWorldTransitionConfig: Equatable, Sendable {
    let enterDuration: TimeInterval
    let exitDuration: TimeInterval
    let worldCameraScale: CGFloat
    let mapCameraScale: CGFloat
    let mapFadeStart: CGFloat
    let worldFadeStart: CGFloat
    let playerFadeStart: CGFloat

    static let standard = MapWorldTransitionConfig(
        enterDuration: 0.65,
        exitDuration: 0.62,
        worldCameraScale: 0.09,
        mapCameraScale: 1.35,
        mapFadeStart: 0.20,
        worldFadeStart: 0.38,
        playerFadeStart: 0.45
    )
}
