enum GameDomainEvent: Equatable, Sendable {
    case puzzleCompleted(PuzzleID)
    case worldEventCompleted(WorldEventID)
    case landmarkActivated(LandmarkID)
    case landmarkReached(LandmarkID)
}
