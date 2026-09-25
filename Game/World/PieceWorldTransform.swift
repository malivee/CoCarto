import CoreGraphics

struct PieceWorldTransform: Equatable, Sendable {
    let origin: CGPoint
    let rotation: GridRotation

    init(piece: WorldPiece, mapper: WorldGridMapper) {
        origin = mapper.worldPosition(for: piece.gridPosition)
        rotation = piece.rotation
    }

    init(origin: CGPoint, rotation: GridRotation) {
        self.origin = origin
        self.rotation = rotation
    }

    func localToWorld(_ point: CGPoint) -> CGPoint {
        let rotated = rotation.rotated(point)
        return CGPoint(x: origin.x + rotated.x, y: origin.y + rotated.y)
    }

    func worldToLocal(_ point: CGPoint) -> CGPoint {
        let translated = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        return rotation.inverse.rotated(translated)
    }
}

extension GridRotation {
    var inverse: GridRotation {
        switch self {
        case .degrees0:
            return .degrees0
        case .degrees90:
            return .degrees270
        case .degrees180:
            return .degrees180
        case .degrees270:
            return .degrees90
        }
    }

    func rotated(_ point: CGPoint) -> CGPoint {
        switch self {
        case .degrees0:
            return point
        case .degrees90:
            return CGPoint(x: -point.y, y: point.x)
        case .degrees180:
            return CGPoint(x: -point.x, y: -point.y)
        case .degrees270:
            return CGPoint(x: point.y, y: -point.x)
        }
    }

    var radians: CGFloat {
        switch self {
        case .degrees0:
            return 0
        case .degrees90:
            return .pi / 2
        case .degrees180:
            return .pi
        case .degrees270:
            return .pi * 1.5
        }
    }
}
