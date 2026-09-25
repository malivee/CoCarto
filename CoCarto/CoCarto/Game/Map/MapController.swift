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

    func rotateSelected(in worldState: WorldState, mapper: MapGridMapper? = nil, locksInteraction: Bool = false) -> PiecePlacementPreview? {
        guard var preview, !isRotatingPiece else {
            return nil
        }

        preview.proposedRotation = preview.proposedRotation.nextQuarterTurn
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
