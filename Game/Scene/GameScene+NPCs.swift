// Penjelasan file: GameScene+NPCs.swift
// Mengelola kehadiran warga desa (NPC: Kakek, Bu Mara, Kenneth, Roland, Anneth)
// dengan model Carto 2.5D MemoryCharacter di sekitar bangunan masing-masing.

import SpriteKit

extension GameScene {
    private static let npcRootName = "villageNPCs"

    var npcRootNode: SKNode {
        if let existing = worldRoot.childNode(withName: Self.npcRootName) {
            return existing
        }
        let node = SKNode()
        node.name = Self.npcRootName
        node.zPosition = 45
        worldRoot.addChild(node)
        return node
    }

    func syncVillageNPCs() {
        let root = npcRootNode
        root.removeAllChildren()

        for object in worldState.buildingObjects {
            guard let buildingPos = buildingWorldPosition(for: object.id) else {
                continue
            }

            let npc: MemoryCharacter
            let offset: CGPoint

            switch object.kind {
            case .arthurHouse:
                npc = MemoryCharacter(
                    title: "Grandpa",
                    color: SKColor(red: 0.48, green: 0.54, blue: 0.42, alpha: 1)
                )
                npc.name = "npc-grandpa"
                npc.useSpriteAsset(named: "kakekArthur", size: CGSize(width: 44, height: 58))
                offset = CGPoint(x: 32, y: -68)
                updateGrandpaBadge(npc)
                if isQuest1TutorialActive,
                   hasMovedArthurInTutorial,
                   !quest1Controller.isWellUnlocked {
                    npc.addChild(makeTutorialHalo())
                }

            case .buMaraHouse:
                npc = MemoryCharacter(
                    title: "Mrs. Mara",
                    color: SKColor(red: 0.76, green: 0.46, blue: 0.36, alpha: 1)
                )
                npc.name = "npc-bumara"
                npc.useSpriteAsset(named: "buMara", size: CGSize(width: 64, height: 48))
                offset = CGPoint(x: 34, y: -68)
                updateBuMaraBadge(npc)

            case .barn:
                npc = MemoryCharacter(
                    title: "Kenneth",
                    color: SKColor(red: 0.78, green: 0.40, blue: 0.26, alpha: 1)
                )
                npc.name = "npc-kenneth"
                npc.useSpriteAsset(named: "kenneth", size: CGSize(width: 44, height: 58))
                offset = CGPoint(x: 28, y: -126)
                updateKennethBadge(npc)

            case .animalPen:
                npc = MemoryCharacter(
                    title: "Roland",
                    color: SKColor(red: 0.89, green: 0.68, blue: 0.27, alpha: 1)
                )
                npc.name = "npc-roland"
                npc.useSpriteAsset(named: "roland", size: CGSize(width: 46, height: 60))
                offset = CGPoint(x: 40, y: -154)
                updateRolandBadge(npc)

            case .annethHouse:
                npc = MemoryCharacter(
                    title: "Anneth",
                    color: SKColor(red: 0.35, green: 0.55, blue: 0.76, alpha: 1)
                )
                npc.name = "npc-anneth"
                npc.useSpriteAsset(named: "ibuAnneth", size: CGSize(width: 44, height: 58))
                offset = CGPoint(x: 34, y: -98)
                updateAnnethBadge(npc)

            case .rockSalt:
                npc = MemoryCharacter(
                    title: "Old Miner",
                    color: SKColor(red: 0.46, green: 0.40, blue: 0.34, alpha: 1)
                )
                npc.name = "npc-rocksalt-miner"
                npc.useSpriteAsset(named: "penambangRocksalt", size: CGSize(width: 46, height: 60))
                offset = CGPoint(x: 22, y: -82)
                updateOldMinerBadge(npc)

            case .well:
                if isQuest1TutorialActive && quest1Controller.isWellUnlocked && !quest1Controller.hasCollectedWater {
                    let wellBadge = makeWellInteractionBadge(objectID: object.id)
                    wellBadge.position = CGPoint(x: buildingPos.x, y: buildingPos.y + 62)
                    root.addChild(wellBadge)
                }
                continue

            }

            npc.setScale(0.7)
            npc.position = groundedNPCPosition(
                for: object,
                buildingPosition: buildingPos,
                preferredOffset: offset
            )
            npc.userData = [
                BuildingObjectRenderer.objectIDKey: object.id.uuidString,
                "npcTitle": npc.title
            ]
            npc.updateDepth()
            root.addChild(npc)
        }
    }

    func updateVillageNPCs(deltaTime: TimeInterval) {
        let dt = CGFloat(deltaTime > 0 ? min(deltaTime, 0.1) : 1.0 / 60.0)
        let root = npcRootNode
        let playerPos = playerNode?.position

        for child in root.children {
            guard let npc = child as? MemoryCharacter else { continue }
            npc.applyMovement(dx: 0, dy: 0, dt: dt)
            npc.updateDepth()

            // Karakter menatap ke arah Arthur jika Arthur berada dekat
            if let playerPos {
                let dist = hypot(playerPos.x - npc.position.x, playerPos.y - npc.position.y)
                if dist < 80 {
                    let dx = playerPos.x - npc.position.x
                    if dx > 4 {
                        npc.visualRoot.xScale = 1.0
                    } else if dx < -4 {
                        npc.visualRoot.xScale = -1.0
                    }
                }
            }
        }
    }

    func npcCharacter(named title: String) -> MemoryCharacter? {
        let root = npcRootNode
        for child in root.children {
            if let npc = child as? MemoryCharacter,
               npc.title.caseInsensitiveCompare(title) == .orderedSame ||
               npc.name?.contains(title.lowercased()) == true {
                return npc
            }
        }
        return nil
    }

    func villageNPC(in stack: [SKNode]) -> MemoryCharacter? {
        stack.compactMap { $0 as? MemoryCharacter }.first
    }

    private func buildingWorldPosition(for objectID: UUID) -> CGPoint? {
        guard let buildingRoot = worldRoot.childNode(withName: BuildingObjectRenderer.rootName) else {
            return nil
        }
        for node in buildingRoot.children {
            if let idString = node.userData?[BuildingObjectRenderer.objectIDKey] as? String,
               idString == objectID.uuidString {
                return node.position
            }
        }
        return nil
    }

    private func groundedNPCPosition(
        for object: BuildingObject,
        buildingPosition: CGPoint,
        preferredOffset: CGPoint
    ) -> CGPoint {
        let microSize = mapper.cellSize / CGFloat(MicroBiomeGrid.dimension)
        let validator = BuildingPlacementValidator()
        let allGround = validator.tilePositions(in: worldState)
        let otherBuildingGround = worldState.buildingObjects
            .filter { $0.id != object.id }
            .reduce(into: Set<GridPosition>()) {
            $0.formUnion($1.occupiedPositions)
        }
        let availableGround = allGround.subtracting(otherBuildingGround)

        let definition = BuildingObjectCatalog.definition(for: object.kind)
        let isQuarterTurn = object.rotation == .degrees90 || object.rotation == .degrees270
        let visualHeightUnits = isQuarterTurn
            ? definition.worldSize.width
            : definition.worldSize.height
        let visualHeight = CGFloat(visualHeightUnits)
            * mapper.cellSize / CGFloat(WorldVisualSubcell.dimension)
            * 1.35
        let lowestSafeFootY = buildingPosition.y - visualHeight / 2 - 2
        let preferredPosition = CGPoint(
            x: buildingPosition.x + preferredOffset.x,
            y: buildingPosition.y + preferredOffset.y
        )

        let frontGround = availableGround.filter {
            worldPositionForMicroGrid($0, microSize: microSize).y <= lowestSafeFootY
        }
        let chosenGround = frontGround.min {
            let left = worldPositionForMicroGrid($0, microSize: microSize)
            let right = worldPositionForMicroGrid($1, microSize: microSize)
            let leftDistance = hypot(left.x - preferredPosition.x, left.y - preferredPosition.y)
            let rightDistance = hypot(right.x - preferredPosition.x, right.y - preferredPosition.y)
            if leftDistance == rightDistance {
                return $0.x < $1.x
            }
            return leftDistance < rightDistance
        }

        return chosenGround.map { worldPositionForMicroGrid($0, microSize: microSize) }
            ?? preferredPosition
    }

    private func worldPositionForMicroGrid(_ position: GridPosition, microSize: CGFloat) -> CGPoint {
        CGPoint(
            x: (CGFloat(position.x) + 0.5) * microSize - mapper.cellSize / 2,
            y: (CGFloat(position.y) + 0.5) * microSize - mapper.cellSize / 2
        )
    }

    private func updateGrandpaBadge(_ npc: MemoryCharacter) {
        if quest1Controller.isCompleted {
            npc.clearStatusBadge()
        } else if quest1Controller.hasCollectedWater {
            npc.setStatusBadge(text: "Talk")
        } else if quest1Controller.isActive {
            npc.setStatusBadge(text: "Talk")
        } else if quest1Controller.canStart(in: worldState) {
            npc.setStatusBadge(text: "Talk")
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateBuMaraBadge(_ npc: MemoryCharacter) {
        let placedBuildings = Set(worldState.buildingObjects.map { VillageQuestCatalog.buildingID(for: $0.kind) })
        if placedBuildings.contains(VillageQuestCatalog.BuildingID.buMaraHouse) {
            npc.setStatusBadge(text: "Talk")
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateKennethBadge(_ npc: MemoryCharacter) {
        if quest3Controller.isCompleted {
            npc.clearStatusBadge()
        } else if quest3Controller.isWaitingForMinigame {
            npc.setStatusBadge(text: "Talk")
        } else if quest3Controller.canStart(in: worldState) {
            npc.setStatusBadge(text: "Talk")
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateRolandBadge(_ npc: MemoryCharacter) {
        if quest4Controller.isCompleted {
            npc.clearStatusBadge()
        } else if quest4Controller.canStart(in: worldState) {
            npc.setStatusBadge(text: "Talk")
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateAnnethBadge(_ npc: MemoryCharacter) {
        if quest5Controller.isCompleted {
            npc.clearStatusBadge()
        } else if quest5Controller.canStart(in: worldState) {
            npc.setStatusBadge(text: "Talk")
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateOldMinerBadge(_ npc: MemoryCharacter) {
        npc.setStatusBadge(text: "Talk")
    }

    private func makeWellInteractionBadge(objectID: UUID) -> SKNode {
        let badge = MemoryCharacter.makeStatusBadge(text: "Use Well")
        badge.name = "WellInteractionBadge"
        badge.zPosition = 60
        badge.userData = [BuildingObjectRenderer.objectIDKey: objectID.uuidString]
        return badge
    }

    private func makeTutorialHalo() -> SKShapeNode {
        let halo = SKShapeNode(ellipseOf: CGSize(width: 48, height: 62))
        halo.name = "TutorialGlow"
        halo.position.y = 8
        halo.fillColor = .clear
        halo.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.24, alpha: 1.0)
        halo.lineWidth = 3
        halo.glowWidth = 5
        halo.zPosition = -1
        halo.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.38, duration: 0.65),
            .fadeAlpha(to: 1.0, duration: 0.65)
        ])))
        return halo
    }
}
