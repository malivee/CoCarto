import CoreGraphics
import Foundation

enum MapInteractionState: Equatable {
    case idle
    case pieceSelected(UUID)
    case draggingPiece(UUID)
    case panningMap
    case rotatingPiece(UUID)
}

final class MapController {
    private let validator = PlacementValidator()
    private(set) var preview: PiecePlacementPreview?
    private(set) var interactionState: MapInteractionState = .idle
    private var dragOffsetFromPieceOrigin: CGPoint = .zero
    private var lastPanTouchPosition: CGPoint?

    var selectedPieceID: UUID? {
        preview?.pieceID
    }

    var isRotatingPiece: Bool {
        if case .rotatingPiece = interactionState {
            return true
        }
        return false
    }

    func canManipulate(pieceID: UUID, in worldState: WorldState, playerState: PlayerState) -> Bool {
        guard let piece = worldState.piece(id: pieceID), piece.isMovable else {
            return false
        }
        guard worldState.canMovePieceWithBuildings(pieceID: pieceID) else {
            return false
        }

        return true
    }

    @discardableResult
    func select(pieceID: UUID, in worldState: WorldState, playerState: PlayerState, mapper: MapGridMapper? = nil) -> PiecePlacementPreview? {
        guard canManipulate(pieceID: pieceID, in: worldState, playerState: playerState),
              let piece = worldState.piece(id: pieceID) else {
            preview = nil
            interactionState = .idle
            return nil
        }

        let snapshot = PiecePlacementSnapshot(
            gridPosition: piece.gridPosition,
            rotation: piece.rotation
        )
        let isValid = validator.canPlace(
            pieceID: pieceID,
            at: piece.gridPosition,
            rotation: piece.rotation,
            in: worldState
        )
        let visualPosition = mapper?.mapPosition(for: piece.gridPosition) ?? .zero

        preview = PiecePlacementPreview(
            pieceID: pieceID,
            originalPlacement: snapshot,
            proposedPosition: piece.gridPosition,
            proposedRotation: piece.rotation,
            visualPosition: visualPosition,
            isValid: isValid
        )
        interactionState = .pieceSelected(pieceID)
        return preview
    }

    func beginDrag(
        pieceID: UUID,
        touchPositionInContent: CGPoint,
        mapper: MapGridMapper,
        worldState: WorldState,
        playerState: PlayerState
    ) -> PiecePlacementPreview? {
        if preview?.pieceID != pieceID {
            _ = select(pieceID: pieceID, in: worldState, playerState: playerState, mapper: mapper)
        }

        guard var preview, preview.pieceID == pieceID else {
            return self.preview
        }

        dragOffsetFromPieceOrigin = CGPoint(
            x: touchPositionInContent.x - preview.visualPosition.x,
            y: touchPositionInContent.y - preview.visualPosition.y
        )
        let proposedVisualPosition = CGPoint(
            x: touchPositionInContent.x - dragOffsetFromPieceOrigin.x,
            y: touchPositionInContent.y - dragOffsetFromPieceOrigin.y
        )
        preview.proposedPosition = mapper.gridPosition(containing: proposedVisualPosition)
        preview.visualPosition = mapper.mapPosition(for: preview.proposedPosition)
        preview.isValid = validator.canPlace(
            pieceID: preview.pieceID,
            at: preview.proposedPosition,
            rotation: preview.proposedRotation,
            in: worldState
        )
        self.preview = preview
        interactionState = .draggingPiece(pieceID)
        return preview
    }

    func updateDrag(touchPositionInContent: CGPoint, mapper: MapGridMapper, worldState: WorldState) -> PiecePlacementPreview? {
        guard var preview else {
            return nil
        }

        let proposedVisualPosition = CGPoint(
            x: touchPositionInContent.x - dragOffsetFromPieceOrigin.x,
            y: touchPositionInContent.y - dragOffsetFromPieceOrigin.y
        )
        preview.proposedPosition = mapper.gridPosition(containing: proposedVisualPosition)
        preview.visualPosition = mapper.mapPosition(for: preview.proposedPosition)
        preview.isValid = validator.canPlace(
            pieceID: preview.pieceID,
            at: preview.proposedPosition,
            rotation: preview.proposedRotation,
            in: worldState
        )
        self.preview = preview
        return preview
    }

    func snapSelectedVisualToGrid(mapper: MapGridMapper) -> PiecePlacementPreview? {
        guard var preview else {
            return nil
        }

        preview.visualPosition = mapper.mapPosition(for: preview.proposedPosition)
        self.preview = preview
        interactionState = .pieceSelected(preview.pieceID)
        dragOffsetFromPieceOrigin = .zero
        return preview
    }

    /// Finalizes the grid position only when the drag ends. If the exact drop
    /// overlaps or has incompatible edges, try a small nearby displacement so
    /// the piece does not jump back across the map.
    func resolveDrop(in worldState: WorldState, mapper: MapGridMapper, nudgeRadius: Int = 2) -> PiecePlacementPreview? {
        guard var preview else { return nil }

        if !preview.isValid {
            let origin = preview.proposedPosition
            let offsets = (-nudgeRadius...nudgeRadius).flatMap { y in
                (-nudgeRadius...nudgeRadius).map { x in GridPosition(x: x, y: y) }
            }.filter { offset in
                let distance = abs(offset.x) + abs(offset.y)
                return distance > 0 && distance <= nudgeRadius
            }.sorted { lhs, rhs in
                let lhsDistance = abs(lhs.x) + abs(lhs.y)
                let rhsDistance = abs(rhs.x) + abs(rhs.y)
                if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
                if abs(lhs.y) != abs(rhs.y) { return abs(lhs.y) < abs(rhs.y) }
                return abs(lhs.x) < abs(rhs.x)
            }

            if let nearby = offsets
                .map({ GridPosition(x: origin.x + $0.x, y: origin.y + $0.y) })
                .first(where: {
                    validator.canPlace(
                        pieceID: preview.pieceID,
                        at: $0,
                        rotation: preview.proposedRotation,
                        in: worldState
                    )
                }) {
                preview.proposedPosition = nearby
                preview.isValid = true
            }
        }

        preview.visualPosition = mapper.mapPosition(for: preview.proposedPosition)
        self.preview = preview
        interactionState = .pieceSelected(preview.pieceID)
        dragOffsetFromPieceOrigin = .zero
        return preview
    }

    /// A moved piece that no longer touches the puzzle belongs back in the bag.
    /// The world state is still unchanged during preview, so cancelling restores
    /// its last confirmed placement without another mutation.
    func shouldReturnSelectedPieceToBag(in worldState: WorldState) -> Bool {
        guard let preview,
              let piece = worldState.piece(id: preview.pieceID),
              preview.proposedPosition != preview.originalPlacement.gridPosition ||
                preview.proposedRotation != preview.originalPlacement.rotation else {
            return false
        }

        let proposedCells = piece.occupiedCells(
            at: preview.proposedPosition,
            rotation: preview.proposedRotation
        )
        let otherCells = worldState.pieces
            .filter { $0.id != preview.pieceID }
            .reduce(into: Set<GridPosition>()) { result, other in
                result.formUnion(other.occupiedCells())
            }

        return !proposedCells.contains { cell in
            Direction.allCases.contains { direction in
                otherCells.contains(cell + direction.gridOffset)
            }
        }
    }

    func rotateSelected(
        clockwise: Bool = true,
        in worldState: WorldState,
        mapper: MapGridMapper? = nil,
        locksInteraction: Bool = false
    ) -> PiecePlacementPreview? {
        guard var preview, !isRotatingPiece else {
            return nil
        }

        // SpriteKit displays the stored positive turn counter-clockwise. Keep the
        // control semantics visual: left advances, right moves to the previous turn.
        preview.proposedRotation = clockwise
            ? preview.proposedRotation.previousQuarterTurn
            : preview.proposedRotation.nextQuarterTurn
        preview.isValid = validator.canPlace(
            pieceID: preview.pieceID,
            at: preview.proposedPosition,
            rotation: preview.proposedRotation,
            in: worldState
        )
        if let mapper {
            preview.visualPosition = mapper.mapPosition(for: preview.proposedPosition)
        }
        self.preview = preview
        interactionState = locksInteraction ? .rotatingPiece(preview.pieceID) : .pieceSelected(preview.pieceID)
        return preview
    }

    func finishRotation() {
        if case .rotatingPiece(let pieceID) = interactionState {
            interactionState = .pieceSelected(pieceID)
        }
    }

    func beginPan(at touchPosition: CGPoint) {
        lastPanTouchPosition = touchPosition
        interactionState = .panningMap
    }

    func updatePan(to touchPosition: CGPoint) -> CGPoint {
        guard let lastPanTouchPosition else {
            self.lastPanTouchPosition = touchPosition
            return .zero
        }

        let delta = CGPoint(
            x: touchPosition.x - lastPanTouchPosition.x,
            y: touchPosition.y - lastPanTouchPosition.y
        )
        self.lastPanTouchPosition = touchPosition
        return delta
    }

    func endGesture() {
        switch interactionState {
        case .draggingPiece(let pieceID):
            interactionState = .pieceSelected(pieceID)
        case .panningMap:
            interactionState = preview.map { .pieceSelected($0.pieceID) } ?? .idle
        case .idle, .pieceSelected, .rotatingPiece:
            break
        }
        lastPanTouchPosition = nil
    }

    func cancel() {
        preview = nil
        dragOffsetFromPieceOrigin = .zero
        lastPanTouchPosition = nil
        interactionState = .idle
    }

    func confirm(worldState: inout WorldState) -> Bool {
        guard let preview, preview.isValid else {
            return false
        }

        let didMove = worldState.movePiece(
            id: preview.pieceID,
            to: preview.proposedPosition,
            rotation: preview.proposedRotation
        )

        if didMove {
            cancel()
        }
        return didMove
    }
}
