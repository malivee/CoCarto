import Foundation

struct GlobalMicroRectangle: Equatable, Hashable, Sendable {
    let origin: GlobalMicroPosition
    let width: Int
    let height: Int

    var area: Int {
        width * height
    }

    func positions() -> [GlobalMicroPosition] {
        (0..<height).flatMap { y in
            (0..<width).map { x in
                GlobalMicroPosition(x: origin.x + x, y: origin.y + y)
            }
        }
    }
}
