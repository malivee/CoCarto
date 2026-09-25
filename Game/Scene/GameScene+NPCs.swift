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
                offset = CGPoint(x: 22, y: -24)
                updateGrandpaBadge(npc)

            case .buMaraHouse:
                npc = MemoryCharacter(
                    title: "Bu Mara",
                    color: SKColor(red: 0.76, green: 0.46, blue: 0.36, alpha: 1)
                )
                npc.name = "npc-bumara"
                offset = CGPoint(x: 26, y: -20)
                updateBuMaraBadge(npc)

            case .barn:
                npc = MemoryCharacter(
                    title: "Kenneth",
                    color: SKColor(red: 0.78, green: 0.40, blue: 0.26, alpha: 1)
                )
                npc.name = "npc-kenneth"
                offset = CGPoint(x: 18, y: -24)
                updateKennethBadge(npc)

            case .animalPen:
                npc = MemoryCharacter(
                    title: "Roland",
                    color: SKColor(red: 0.89, green: 0.68, blue: 0.27, alpha: 1)
                )
                npc.name = "npc-roland"
                offset = CGPoint(x: 28, y: -26)
                updateRolandBadge(npc)

            case .annethHouse:
                npc = MemoryCharacter(
                    title: "Anneth",
                    color: SKColor(red: 0.35, green: 0.55, blue: 0.76, alpha: 1)
                )
                npc.name = "npc-anneth"
                offset = CGPoint(x: 24, y: -22)
                updateAnnethBadge(npc)

            default:
                continue
            }

            npc.setScale(0.7)
            npc.position = CGPoint(x: buildingPos.x + offset.x, y: buildingPos.y + offset.y)
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

    private func updateGrandpaBadge(_ npc: MemoryCharacter) {
        if quest1Controller.isCompleted {
            npc.clearStatusBadge()
        } else if quest1Controller.hasCollectedWater {
            npc.setStatusBadge(icon: "💧", text: "Air Sumur", color: .systemCyan)
        } else if quest1Controller.isActive {
            npc.setStatusBadge(icon: "!", text: "Bicara", color: .systemYellow)
        } else if quest1Controller.canStart(in: worldState) {
            npc.setStatusBadge(icon: "!", text: "Bicara", color: .systemYellow)
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateBuMaraBadge(_ npc: MemoryCharacter) {
        let placedBuildings = Set(worldState.buildingObjects.map { VillageQuestCatalog.buildingID(for: $0.kind) })
        if placedBuildings.contains(VillageQuestCatalog.BuildingID.buMaraHouse) {
            npc.setStatusBadge(icon: "🏺", text: "Gerabah", color: .systemOrange)
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateKennethBadge(_ npc: MemoryCharacter) {
        if quest3Controller.isCompleted {
            npc.clearStatusBadge()
        } else if quest3Controller.isWaitingForMinigame {
            npc.setStatusBadge(icon: "🌾", text: "Benih", color: .systemGreen)
        } else if quest3Controller.canStart(in: worldState) {
            npc.setStatusBadge(icon: "🧺", text: "Keranjang", color: .systemYellow)
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateRolandBadge(_ npc: MemoryCharacter) {
        if quest4Controller.isCompleted {
            npc.clearStatusBadge()
        } else if quest4Controller.canStart(in: worldState) {
            npc.setStatusBadge(icon: "!", text: "Bicara", color: .systemYellow)
        } else {
            npc.clearStatusBadge()
        }
    }

    private func updateAnnethBadge(_ npc: MemoryCharacter) {
        if quest5Controller.isCompleted {
            npc.clearStatusBadge()
        } else if quest5Controller.canStart(in: worldState) {
            npc.setStatusBadge(icon: "!", text: "Bicara", color: .systemYellow)
        } else {
            npc.clearStatusBadge()
        }
    }
}
