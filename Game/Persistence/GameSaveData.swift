struct GameSaveData: Codable, Equatable, Sendable {
    let version: Int
    var worldState: WorldState
    var playerState: PlayerSpatialState
    var progressState: WorldProgressState

    init(
        version: Int = SaveVersion.current,
        worldState: WorldState,
        playerState: PlayerSpatialState,
        progressState: WorldProgressState
    ) {
        self.version = version
        self.worldState = worldState
        self.playerState = playerState
        self.progressState = progressState
    }
}
