import Foundation

enum GameMode: Equatable {
    case exploring
    case enteringMap
    case mapIdle
    case mapPieceSelected(UUID)
    case mapDragging(UUID)
    case committingMapChange
    case exitingMap

    var isMapInteractionActive: Bool {
        switch self {
        case .mapIdle, .mapPieceSelected, .mapDragging:
            return true
        case .exploring, .enteringMap, .committingMapChange, .exitingMap:
            return false
        }
    }

    var debugLabel: String {
        switch self {
        case .exploring:
            return "WORLD"
        case .enteringMap:
            return "ENTERING MAP"
        case .mapIdle:
            return "MAP"
        case .mapPieceSelected:
            return "MAP SELECTED"
        case .mapDragging:
            return "MAP DRAGGING"
        case .committingMapChange:
            return "COMMITTING"
        case .exitingMap:
            return "EXITING MAP"
        }
    }
}
