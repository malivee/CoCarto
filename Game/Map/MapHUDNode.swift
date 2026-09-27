import SpriteKit
import UIKit

struct MapQuestItem {
    let category: String
    let title: String
    let isCompleted: Bool
    let buildingKind: BuildingObjectKind?

    init(category: String, title: String, isCompleted: Bool, buildingKind: BuildingObjectKind? = nil) {
        self.category = category
        self.title = title
        self.isCompleted = isCompleted
        self.buildingKind = buildingKind
    }
}

enum MapTutorialStep: Equatable {
    case selectTile
    case rotateTile
    case tryMismatchedTile
    case tryMatchingTile(isValid: Bool)
    case openSidebar
    case buildingSize(BuildingObjectKind)
    case questRequirement(BuildingObjectKind)
    case dragHouse
    case tryWrongSoil(BuildingObjectKind)
    case placeHouse(isValid: Bool)
    case dragWell
    case placeWell(isValid: Bool)
    case enterWorld
    case newBuilding(openInventory: Bool)

    var badge: String {
        switch self {
        case .selectTile: return "1"
        case .rotateTile: return "2"
        case .tryMismatchedTile: return "3"
        case .tryMatchingTile: return "4"
        case .openSidebar: return "5"
        case .buildingSize: return "6"
        case .tryWrongSoil, .placeHouse: return "7"
        case .questRequirement: return "8"
        case .dragWell, .placeWell: return "9"
        case .dragHouse: return "6"
        case .enterWorld: return "10"
        case .newBuilding: return "+1"
        }
    }

    var title: String {
        switch self {
        case .selectTile:
            return "Select a Tile"
        case .rotateTile:
            return "Rotate the Tile"
        case .tryMismatchedTile:
            return "Try the Wrong Color"
        case .tryMatchingTile(let isValid):
            return isValid ? "Colors Match" : "Find the Same Color"
        case .openSidebar:
            return "Open Buildings"
        case .buildingSize:
            return "Building Footprint"
        case .questRequirement:
            return "Quest Requirement"
        case .dragHouse:
            return "Drag Arthur's House"
        case .tryWrongSoil:
            return "Try Non-Village Soil"
        case .placeHouse(let isValid):
            return isValid ? "Drop It Here" : "Find Village Soil"
        case .dragWell:
            return "Drag the Well"
        case .placeWell(let isValid):
            return isValid ? "Drop It Here" : "Find Village Soil"
        case .newBuilding:
            return "New Building Unlocked!"
        case .enterWorld:
            return "Enter the Village"
        }
    }

    var subtitle: String {
        switch self {
        case .selectTile:
            return "Tap the highlighted tile first."
        case .rotateTile:
            return "Use rotate until the tile is facing the edge you want to test."
        case .tryMismatchedTile:
            return "Drag it so different-colored edges touch. It will bounce away."
        case .tryMatchingTile(let isValid):
            return isValid
                ? "Good. Release it to connect the matching colors."
                : "Now drag it so same-colored edges touch."
        case .openSidebar:
            return "Open the Buildings tab."
        case .buildingSize(let kind):
            let definition = BuildingObjectCatalog.definition(for: kind)
            return "\(definition.title) needs \(definition.mapWidth) x \(definition.mapHeight) squares; each map tile has small soil squares."
        case .questRequirement(let kind):
            let definition = BuildingObjectCatalog.definition(for: kind)
            return "The top-right requirement shows what the quest needs. Now place \(definition.title)."
        case .dragHouse:
            return "Drag Arthur's House from Buildings."
        case .tryWrongSoil(let kind):
            let definition = BuildingObjectCatalog.definition(for: kind)
            return "Try \(definition.title) on non-village soil. This building type does not fit there."
        case .placeHouse(let isValid):
            let definition = BuildingObjectCatalog.definition(for: .arthurHouse)
            return isValid
                ? "Correct: village soil fits this \(definition.mapWidth) x \(definition.mapHeight) building."
                : "Move the full footprint onto village soil until it turns green."
        case .dragWell:
            return "Drag the Well from Buildings. It needs 4 x 4 squares."
        case .placeWell(let isValid):
            let definition = BuildingObjectCatalog.definition(for: .well)
            return isValid
                ? "Correct: village soil fits this \(definition.mapWidth) x \(definition.mapHeight) building."
                : "Move the full footprint onto village soil until it turns green."
        case .newBuilding(let openInventory):
            return openInventory ? "Open Buildings." : "Buildings can only be placed on village soil."
        case .enterWorld:
            return "Tap ENTER WORLD to start exploring."
        }
    }
}

final class TutorialBannerNode: SKNode {
    private let background = SKShapeNode()
    private let innerBorder = SKShapeNode()
    private let sealBg = SKShapeNode()
    private let sealIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let subLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")

    override init() {
        super.init()
        zPosition = 50
        name = "TutorialBanner"

        background.fillColor = SKColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 0.96)
        background.strokeColor = SKColor(red: 0.36, green: 0.24, blue: 0.16, alpha: 0.95)
        background.lineWidth = 2.0
        addChild(background)

        innerBorder.fillColor = .clear
        innerBorder.strokeColor = SKColor(red: 0.84, green: 0.68, blue: 0.34, alpha: 0.70)
        innerBorder.lineWidth = 1.0
        addChild(innerBorder)

        sealBg.fillColor = SKColor(red: 0.74, green: 0.28, blue: 0.22, alpha: 1.0)
        sealBg.strokeColor = SKColor(red: 0.92, green: 0.78, blue: 0.42, alpha: 1.0)
        sealBg.lineWidth = 1.2
        addChild(sealBg)

        sealIcon.fontSize = 17
        sealIcon.verticalAlignmentMode = .center
        sealIcon.horizontalAlignmentMode = .center
        addChild(sealIcon)

        titleLabel.fontSize = 13.5
        titleLabel.fontColor = SKColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 1.0)
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        addChild(titleLabel)

        subLabel.fontSize = 11.5
        subLabel.fontColor = SKColor(red: 0.44, green: 0.32, blue: 0.22, alpha: 1.0)
        subLabel.horizontalAlignmentMode = .left
        subLabel.verticalAlignmentMode = .center
        subLabel.numberOfLines = 2
        subLabel.lineBreakMode = .byWordWrapping
        addChild(subLabel)

        let bobUp = SKAction.moveBy(x: 0, y: 2.5, duration: 1.4)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveBy(x: 0, y: -2.5, duration: 1.4)
        bobDown.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])))
    }

    required init?(coder aDecoder: NSCoder) { nil }

    func update(with step: MapTutorialStep?, maxWidth: CGFloat) {
        guard let step else {
            isHidden = true
            return
        }
        isHidden = false

        let bannerWidth = min(maxWidth, 390)
        let bannerHeight: CGFloat = 68

        background.path = CGPath(
            roundedRect: CGRect(x: -bannerWidth / 2, y: -bannerHeight / 2, width: bannerWidth, height: bannerHeight),
            cornerWidth: 15,
            cornerHeight: 15,
            transform: nil
        )

        innerBorder.path = CGPath(
            roundedRect: CGRect(x: -bannerWidth / 2 + 3, y: -bannerHeight / 2 + 3, width: bannerWidth - 6, height: bannerHeight - 6),
            cornerWidth: 12,
            cornerHeight: 12,
            transform: nil
        )

        let sealRadius: CGFloat = 18
        let sealX = -bannerWidth / 2 + 24
        sealBg.path = CGPath(ellipseIn: CGRect(x: sealX - sealRadius, y: -sealRadius, width: sealRadius * 2, height: sealRadius * 2), transform: nil)
        sealIcon.text = step.badge
        sealIcon.position = CGPoint(x: sealX, y: -1)

        let textX = sealX + sealRadius + 14
        let textWidth = bannerWidth - (textX - (-bannerWidth / 2)) - 14

        titleLabel.text = step.title
        titleLabel.position = CGPoint(x: textX, y: 11)
        titleLabel.preferredMaxLayoutWidth = textWidth

        subLabel.text = step.subtitle
        subLabel.position = CGPoint(x: textX, y: -11)
        subLabel.preferredMaxLayoutWidth = textWidth
    }
}

final class MapHUDNode: SKNode {

    static let inventoryItemHeight: CGFloat = 112
    static let inventoryPanelHeight: CGFloat = 392

    private let inventoryToggle = MapButtonNode(

        title: "BUILD  +",

        name: MapNodeName.inventoryToggle.rawValue,

        size: CGSize(width: 228, height: 68),

        borderless: false,

        fontSize: 17

    )

    private let questPanel = QuestTrackerNode()

    private let rotateLeftButton = RotationButtonNode(

        direction: .left,

        name: MapNodeName.rotateLeftButton.rawValue,

        size: 104

    )

    private let rotateRightButton = RotationButtonNode(

        direction: .right,

        name: MapNodeName.rotateRightButton.rawValue,

        size: 104

    )

    private let inventoryPanel = SKShapeNode()

    private let inventoryDivider = SKShapeNode()

    private let inventoryCrop = SKCropNode()

    private let inventoryContent = SKNode()
    private let inventoryScrollTrack = SKShapeNode()
    private let inventoryScrollThumb = SKShapeNode()
    private let newBuildingBadge = SKShapeNode()
    private let newBuildingBadgeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let emptyInventoryLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

    private let selectionTray = SKShapeNode()

    private let selectionControls = SKNode()
    private let objectStatus = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let placeObjectButton = MapButtonNode(title: "PLACE", name: MapNodeName.confirmButton.rawValue)
    private let cancelObjectButton = MapButtonNode(title: "CANCEL", name: MapNodeName.cancelButton.rawValue)
    private let enterWorldButton = MapButtonNode(
        title: "ENTER WORLD  ▶",
        name: MapNodeName.enterWorldButton.rawValue,
        size: CGSize(width: 218, height: 58),
        fontSize: 17
    )
    private let tutorialBanner = TutorialBannerNode()
    private var inventoryItemNodes: [BuildingObjectKind: SKNode] = [:]

    private let inventoryKinds: [BuildingObjectKind]
    private let newInventoryKinds: Set<BuildingObjectKind>

//    private let inventoryItems = ["House", "Workshop", "Farm", "Market", "Bridge", "Tower"]

    private let itemHeight = MapHUDNode.inventoryItemHeight

    private let panelSize = CGSize(width: 228, height: MapHUDNode.inventoryPanelHeight)


    init(inventoryKinds: [BuildingObjectKind], newInventoryKinds: Set<BuildingObjectKind> = []) {

        self.inventoryKinds = inventoryKinds
        self.newInventoryKinds = newInventoryKinds

        super.init()

        name = MapNodeName.hud.rawValue

        zPosition = 600

        configureInventory()

        configureNewBuildingBadge()

        configureSelectionControls()

        configureQuestTracker()

        configureTutorialNodes()

        addChild(inventoryToggle)
        addChild(enterWorldButton)

    }


    func layout(

        cameraCenter: CGPoint,

        sceneSize: CGSize,

        preview: PiecePlacementPreview?,

        inventoryExpanded: Bool,

        inventoryScrollOffset: CGFloat,

        inventorySelectionTitle: String,
        animateSelection: Bool,
        selectedObjectKind: BuildingObjectKind? = nil,
        objectPreview: BuildingObject? = nil,
        objectResult: BuildingPlacementResult? = nil,
        questItems: [MapQuestItem],
        tutorialStep: MapTutorialStep? = nil
    ) {

        let cameraScale: CGFloat = 1.35

        let halfWidth = sceneSize.width * cameraScale / 2

        let halfHeight = sceneSize.height * cameraScale / 2

        let sideInset: CGFloat = 14

        let topY = cameraCenter.y + halfHeight - 116


        inventoryToggle.position = CGPoint(x: cameraCenter.x - halfWidth + sideInset + panelSize.width / 2, y: topY)

        inventoryToggle.setTitle(inventoryExpanded ? "CLOSE  ×" : "BUILD  +")

        inventoryPanel.position = CGPoint(

            x: cameraCenter.x - halfWidth + sideInset + panelSize.width / 2,

            y: topY - 40 - panelSize.height / 2

        )

        inventoryPanel.isHidden = !inventoryExpanded
        updateNewBuildingBadge(isInventoryExpanded: inventoryExpanded)

        questPanel.position = CGPoint(
            x: cameraCenter.x + halfWidth - sideInset - 143,
            y: topY - (questItems.count >= 3 ? 45 : 22)
        )

        questPanel.update(with: Array(questItems.prefix(3)))
        questPanel.isHidden = questItems.isEmpty || (inventoryExpanded && sceneSize.width * cameraScale < 530)

        // Keep tutorial copy inside the top HUD row, away from the inventory
        // list and the bottom placement controls.
        let bannerY = inventoryExpanded ? topY - 40 - panelSize.height - 38 : topY - 78
        tutorialBanner.position = CGPoint(x: cameraCenter.x, y: bannerY)
        let bannerMaxWidth = min(halfWidth * 2 - 40, 420)
        tutorialBanner.update(with: tutorialStep, maxWidth: bannerMaxWidth)

        updateTutorialHighlights(for: tutorialStep)


        let trayHeight: CGFloat = 216

        let trayY = cameraCenter.y - halfHeight + trayHeight / 2

        selectionTray.path = CGPath(

            rect: CGRect(x: -halfWidth, y: -trayHeight / 2, width: halfWidth * 2, height: trayHeight),

            transform: nil

        )

        selectionTray.position = CGPoint(x: cameraCenter.x, y: trayY)
        let isTrayVisible = preview != nil || selectedObjectKind != nil
        selectionTray.isHidden = !isTrayVisible
        enterWorldButton.position = CGPoint(
            x: cameraCenter.x,
            y: cameraCenter.y - halfHeight + 48
        )
        enterWorldButton.isHidden = isTrayVisible || inventoryExpanded
        objectStatus.preferredMaxLayoutWidth = halfWidth * 2 - 30

        if let selectedObjectKind {
            // BUILDINGS: DO NOT ROTATE BUILDINGS!
            selectionControls.isHidden = true
            rotateLeftButton.removeAction(forKey: "rotatePulse")
            rotateRightButton.removeAction(forKey: "rotatePulse")
            rotateLeftButton.setScale(1.0)
            rotateRightButton.setScale(1.0)

            let definition = BuildingObjectCatalog.definition(for: selectedObjectKind)
            objectStatus.isHidden = false
            let isValid = objectResult == .valid
            let statusText = isValid ? "● Ready to Place" : "○ " + (objectResult?.message ?? "Move it onto village soil")
            let dimensions = objectPreview?.mapDimensions
                ?? (width: definition.mapWidth, height: definition.mapHeight)
            objectStatus.text = "\(definition.title)\nFootprint: \(dimensions.width) × \(dimensions.height) grid squares\n\(statusText)"
            objectStatus.fontColor = isValid ? SKColor(red: 0.4, green: 0.95, blue: 0.5, alpha: 1.0) : SKColor(red: 0.98, green: 0.75, blue: 0.35, alpha: 1.0)
            objectStatus.numberOfLines = 3
            objectStatus.position.y = 78

            placeObjectButton.position = CGPoint(x: 75, y: -25)
            cancelObjectButton.position = CGPoint(x: -75, y: -25)
            placeObjectButton.setTitle("✓ Place")
            cancelObjectButton.setTitle("✕ Cancel")
            let isTryingWrongSoil: Bool
            if case .tryWrongSoil = tutorialStep {
                isTryingWrongSoil = true
            } else {
                isTryingWrongSoil = false
            }
            placeObjectButton.isHidden = false
            cancelObjectButton.isHidden = false
            placeObjectButton.setEnabled(isValid && !isTryingWrongSoil)
        } else if preview != nil {
            objectStatus.numberOfLines = 2
            // TILE PIECES: ROTATION ACTIVE!
            selectionControls.isHidden = false
            selectionControls.position.y = 44
            selectionControls.setScale(1.0)

            objectStatus.isHidden = false
            let isValid = preview?.isValid == true
            let alignText = isValid ? "● Position Valid" : "○ Edges Do Not Match"
            objectStatus.text = "Map Tile · \(alignText) · Rotate with ⟲ / ⟳"
            objectStatus.fontColor = isValid ? SKColor(red: 0.4, green: 0.95, blue: 0.5, alpha: 1.0) : SKColor(red: 0.98, green: 0.75, blue: 0.35, alpha: 1.0)
            objectStatus.position.y = 94

            placeObjectButton.position = CGPoint(x: 66, y: -65)
            cancelObjectButton.position = CGPoint(x: -66, y: -65)
            placeObjectButton.setTitle("✓ Done")
            cancelObjectButton.setTitle("✕ Cancel")
            placeObjectButton.isHidden = false
            cancelObjectButton.isHidden = false
            placeObjectButton.setEnabled(isValid)

            rotateLeftButton.removeAction(forKey: "rotatePulse")
            rotateRightButton.removeAction(forKey: "rotatePulse")
            let pulse = SKAction.sequence([
                .scale(to: 1.08, duration: 0.6),
                .scale(to: 1.0, duration: 0.6)
            ])
            rotateLeftButton.run(.repeatForever(pulse), withKey: "rotatePulse")
            rotateRightButton.run(.repeatForever(pulse), withKey: "rotatePulse")
        } else {
            selectionControls.isHidden = true
            objectStatus.isHidden = true
            placeObjectButton.isHidden = true
            cancelObjectButton.isHidden = true
            rotateLeftButton.removeAction(forKey: "rotatePulse")
            rotateRightButton.removeAction(forKey: "rotatePulse")
            rotateLeftButton.setScale(1.0)
            rotateRightButton.setScale(1.0)
        }

        if animateSelection, isTrayVisible {

            selectionTray.position.y = trayY - trayHeight

            let reveal = SKAction.moveTo(y: trayY, duration: 0.11)

            reveal.timingMode = .easeOut

            selectionTray.run(reveal, withKey: "revealSelectionTray")

        }

        inventoryContent.position.y = inventoryScrollOffset
        updateInventoryScrollIndicator(offset: inventoryScrollOffset)

    }

    private func configureTutorialNodes() {
        addChild(tutorialBanner)
    }

    private func updateTutorialHighlights(for step: MapTutorialStep?) {
        inventoryToggle.setTutorialHighlighted(step == .openSidebar || step == .newBuilding(openInventory: true))
        rotateLeftButton.setTutorialHighlighted(false)
        rotateRightButton.setTutorialHighlighted(false)
        placeObjectButton.setTutorialHighlighted(false)
        // HEAD: questPanel.setTutorialHighlighted(false)
        enterWorldButton.setTutorialHighlighted(step == .enterWorld)
        inventoryItemNodes.values.forEach {
            $0.childNode(withName: "TutorialGlow")?.removeFromParent()
        }

        switch step {
        case .rotateTile, .tryMismatchedTile, .tryMatchingTile:
            rotateLeftButton.setTutorialHighlighted(true)
            rotateRightButton.setTutorialHighlighted(true)
        case .newBuilding(openInventory: false):
            addTutorialGlow(to: inventoryItemNodes[.buMaraHouse])
        case .buildingSize(let kind):
            addTutorialGlow(to: inventoryItemNodes[kind])
        case .dragHouse:
            addTutorialGlow(to: inventoryItemNodes[.arthurHouse])
        case .dragWell:
            addTutorialGlow(to: inventoryItemNodes[.well])
        case .questRequirement:
            questPanel.setTutorialHighlighted(true)
            addTutorialGlow(to: inventoryItemNodes[.well])
        case .tryWrongSoil(let kind):
            addTutorialGlow(to: inventoryItemNodes[kind])
        case .placeHouse(let isValid), .placeWell(let isValid):
            if isValid { placeObjectButton.setTutorialHighlighted(true) }
        default:
            break
        }
    }

    private func addTutorialGlow(to node: SKNode?) {
        guard let node else { return }
        let glow = SKShapeNode(
            rectOf: CGSize(width: panelSize.width - 8, height: itemHeight + 2),
            cornerRadius: 10
        )
        glow.name = "TutorialGlow"
        glow.fillColor = .clear
        glow.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.24, alpha: 1.0)
        glow.glowWidth = 4
        glow.lineWidth = 3
        glow.zPosition = 20
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.42, duration: 0.65),
            .fadeAlpha(to: 1.0, duration: 0.65)
        ])))
        node.addChild(glow)
    }

    private func configureQuestTracker() {
        questPanel.zPosition = 12
        addChild(questPanel)
    }


    private func configureInventory() {

        inventoryPanel.name = MapNodeName.inventoryPanel.rawValue

        inventoryPanel.path = CGPath(

            roundedRect: CGRect(origin: CGPoint(x: -panelSize.width / 2, y: -panelSize.height / 2), size: panelSize),

            cornerWidth: 22,

            cornerHeight: 22,

            transform: nil

        )

        inventoryPanel.fillColor = SKColor(red: 0.10, green: 0.11, blue: 0.10, alpha: 0.97)

        inventoryPanel.strokeColor = SKColor.white.withAlphaComponent(0.20)
        inventoryPanel.lineWidth = 1

        inventoryPanel.zPosition = 10

        addChild(inventoryPanel)


        inventoryDivider.path = CGPath(

            rect: CGRect(x: -panelSize.width / 2 + 14, y: panelSize.height / 2 - 1, width: panelSize.width - 28, height: 1),

            transform: nil

        )

        inventoryDivider.fillColor = SKColor.white.withAlphaComponent(0.24)

        inventoryDivider.strokeColor = .clear

        inventoryDivider.zPosition = 3

        inventoryPanel.addChild(inventoryDivider)


        let mask = SKShapeNode(rectOf: CGSize(width: panelSize.width - 8, height: panelSize.height - 8), cornerRadius: 18)

        mask.fillColor = .white

        inventoryCrop.maskNode = mask

        inventoryCrop.name = MapNodeName.inventoryPanel.rawValue

        inventoryPanel.addChild(inventoryCrop)

        inventoryCrop.addChild(inventoryContent)

        inventoryScrollTrack.path = CGPath(
            roundedRect: CGRect(x: -2, y: -(panelSize.height - 28) / 2, width: 4, height: panelSize.height - 28),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        inventoryScrollTrack.position.x = panelSize.width / 2 - 9
        inventoryScrollTrack.fillColor = SKColor.white.withAlphaComponent(0.12)
        inventoryScrollTrack.strokeColor = .clear
        inventoryScrollTrack.zPosition = 8
        inventoryPanel.addChild(inventoryScrollTrack)

        inventoryScrollThumb.fillColor = SKColor(red: 0.98, green: 0.72, blue: 0.24, alpha: 0.92)
        inventoryScrollThumb.strokeColor = .clear
        inventoryScrollThumb.zPosition = 9
        inventoryPanel.addChild(inventoryScrollThumb)

        emptyInventoryLabel.text = "ALL BUILDINGS PLACED\nNew buildings unlock through quests."
        emptyInventoryLabel.fontSize = 15
        emptyInventoryLabel.fontColor = SKColor.white.withAlphaComponent(0.78)
        emptyInventoryLabel.numberOfLines = 0
        emptyInventoryLabel.horizontalAlignmentMode = .center
        emptyInventoryLabel.verticalAlignmentMode = .center
        emptyInventoryLabel.preferredMaxLayoutWidth = panelSize.width - 36
        emptyInventoryLabel.zPosition = 4
        emptyInventoryLabel.isHidden = !inventoryKinds.isEmpty
        inventoryPanel.addChild(emptyInventoryLabel)


        for (index, kind) in inventoryKinds.enumerated() {

            let title = BuildingObjectCatalog.definition(for: kind).title

            let item = makeInventoryItem(title: title, index: index, isNew: newInventoryKinds.contains(kind))

            item.position = CGPoint(x: 0, y: panelSize.height / 2 - 10 - itemHeight / 2 - CGFloat(index) * itemHeight)

            inventoryContent.addChild(item)
            inventoryItemNodes[kind] = item

        }

    }


    private func makeInventoryItem(title: String, index: Int, isNew: Bool) -> SKNode {
        let root = SKNode()
        root.name = MapNodeName.inventoryItem.rawValue
        root.userData = ["inventoryIndex": index]

        let kind = inventoryKinds[index]
        let definition = BuildingObjectCatalog.definition(for: kind)

        let hitArea = SKShapeNode(
            rectOf: CGSize(width: panelSize.width - 28, height: itemHeight - 10),
            cornerRadius: 10
        )
        hitArea.name = MapNodeName.inventoryItem.rawValue
        hitArea.userData = ["inventoryIndex": index]
        hitArea.fillColor = SKColor.white.withAlphaComponent(0.06)
        hitArea.strokeColor = SKColor.white.withAlphaComponent(0.12)
        hitArea.lineWidth = 1
        root.addChild(hitArea)

        let thumbnailPlate = SKShapeNode(rectOf: CGSize(width: 52, height: 52), cornerRadius: 10)
        thumbnailPlate.position = CGPoint(x: -65, y: 17)
        thumbnailPlate.fillColor = SKColor(red: 0.95, green: 0.89, blue: 0.74, alpha: 0.94)
        thumbnailPlate.strokeColor = SKColor(red: 0.94, green: 0.68, blue: 0.19, alpha: 0.72)
        thumbnailPlate.lineWidth = 1.5
        root.addChild(thumbnailPlate)

        if let assetName = BuildingObjectRenderer.assetName(for: kind) {
            let texture = SKTexture(imageNamed: assetName)
            let textureSize = texture.size()
            let maximumSize = CGSize(width: 44, height: 44)
            let scale = min(
                maximumSize.width / max(textureSize.width, 1),
                maximumSize.height / max(textureSize.height, 1)
            )
            let thumbnail = SKSpriteNode(texture: texture)
            thumbnail.name = MapNodeName.inventoryItem.rawValue
            thumbnail.size = CGSize(
                width: textureSize.width * scale,
                height: textureSize.height * scale
            )
            thumbnail.zPosition = 2
            thumbnailPlate.addChild(thumbnail)
        }

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = title
        label.fontSize = 15
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 117
        label.lineBreakMode = .byWordWrapping
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -28, y: 20)
        root.addChild(label)

        let dimensions = SKLabelNode(fontNamed: "AvenirNext-Regular")
        dimensions.text = "\(definition.mapWidth) × \(definition.mapHeight) grid squares"
        dimensions.fontSize = 13
        dimensions.fontColor = SKColor.white.withAlphaComponent(0.72)
        dimensions.horizontalAlignmentMode = .left
        dimensions.position = CGPoint(x: -88, y: -24)
        root.addChild(dimensions)

        let dragHint = SKLabelNode(fontNamed: "AvenirNext-Bold")
        dragHint.text = "Tap or drag right"
        dragHint.fontSize = 11
        dragHint.fontColor = SKColor.white.withAlphaComponent(0.52)
        dragHint.horizontalAlignmentMode = .right
        dragHint.position = CGPoint(x: 88, y: -42)
        root.addChild(dragHint)

        if isNew {
            let badge = SKShapeNode(rectOf: CGSize(width: 38, height: 18), cornerRadius: 6)
            badge.position = CGPoint(x: -68, y: -38)
            badge.fillColor = SKColor(red: 0.92, green: 0.43, blue: 0.16, alpha: 1)
            badge.strokeColor = SKColor(red: 1, green: 0.82, blue: 0.34, alpha: 1)
            badge.lineWidth = 1
            let badgeText = SKLabelNode(fontNamed: "AvenirNext-Bold")
            badgeText.text = "NEW"
            badgeText.fontSize = 10
            badgeText.fontColor = .white
            badgeText.verticalAlignmentMode = .center
            badgeText.position.y = -1
            badge.addChild(badgeText)
            root.addChild(badge)
        }

        return root
    }

    private func configureNewBuildingBadge() {
        newBuildingBadge.path = CGPath(
            roundedRect: CGRect(x: -36, y: -13, width: 72, height: 26),
            cornerWidth: 13,
            cornerHeight: 13,
            transform: nil
        )
        newBuildingBadge.position = CGPoint(x: 68, y: 30)
        newBuildingBadge.fillColor = SKColor(red: 0.92, green: 0.34, blue: 0.14, alpha: 1)
        newBuildingBadge.strokeColor = SKColor(red: 1, green: 0.84, blue: 0.38, alpha: 1)
        newBuildingBadge.lineWidth = 1.5
        newBuildingBadge.zPosition = 20
        inventoryToggle.addChild(newBuildingBadge)

        newBuildingBadgeLabel.fontSize = 11
        newBuildingBadgeLabel.fontColor = .white
        newBuildingBadgeLabel.verticalAlignmentMode = .center
        newBuildingBadgeLabel.position.y = -1
        newBuildingBadge.addChild(newBuildingBadgeLabel)
    }

    private func updateNewBuildingBadge(isInventoryExpanded: Bool) {
        let count = newInventoryKinds.count
        newBuildingBadge.isHidden = count == 0
        newBuildingBadgeLabel.text = "+\(count)"
        newBuildingBadge.removeAction(forKey: "newBuildingPulse")
        newBuildingBadge.setScale(1)
        if count > 0 && !isInventoryExpanded {
            let pulse = SKAction.sequence([
                .scale(to: 1.08, duration: 0.55),
                .scale(to: 1.0, duration: 0.55)
            ])
            pulse.timingMode = .easeInEaseOut
            newBuildingBadge.run(.repeatForever(pulse), withKey: "newBuildingPulse")
        }
    }

    private func updateInventoryScrollIndicator(offset: CGFloat) {
        let contentHeight = CGFloat(inventoryKinds.count) * itemHeight + 20
        let viewportHeight = panelSize.height - 8
        let maximumOffset = max(0, contentHeight - viewportHeight)
        inventoryScrollTrack.isHidden = maximumOffset == 0
        inventoryScrollThumb.isHidden = maximumOffset == 0
        guard maximumOffset > 0 else { return }

        let trackHeight = panelSize.height - 28
        let thumbHeight = max(42, trackHeight * viewportHeight / contentHeight)
        inventoryScrollThumb.path = CGPath(
            roundedRect: CGRect(x: -3, y: -thumbHeight / 2, width: 6, height: thumbHeight),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        let travel = trackHeight - thumbHeight
        inventoryScrollThumb.position = CGPoint(
            x: panelSize.width / 2 - 9,
            y: travel / 2 - (min(max(offset, 0), maximumOffset) / maximumOffset) * travel
        )
    }


    private func configureSelectionControls() {

        selectionTray.fillColor = SKColor(red: 0.10, green: 0.11, blue: 0.10, alpha: 0.97)

        selectionTray.strokeColor = .clear

        selectionTray.zPosition = 20

        addChild(selectionTray)


        selectionControls.zPosition = 20

        selectionControls.position.y = 44

        selectionTray.addChild(selectionControls)


        rotateLeftButton.position = CGPoint(x: -92, y: 0)

        rotateRightButton.position = CGPoint(x: 92, y: 0)

        selectionControls.addChild(rotateLeftButton)

        selectionControls.addChild(rotateRightButton)
        objectStatus.fontSize = 15
        objectStatus.numberOfLines = 2
        objectStatus.verticalAlignmentMode = .top
        objectStatus.position.y = 94
        selectionTray.addChild(objectStatus)
        placeObjectButton.position = CGPoint(x: 66, y: -65)
        cancelObjectButton.position = CGPoint(x: -66, y: -65)
        selectionTray.addChild(placeObjectButton)
        selectionTray.addChild(cancelObjectButton)

    }


    @available(*, unavailable)

    required init?(coder aDecoder: NSCoder) { nil }

}


enum RotationButtonDirection {

    case left

    case right

}


final class RotationButtonNode: SKNode {

    private let tutorialGlow: SKShapeNode

    init(direction: RotationButtonDirection, name: String, size: CGFloat) {

        tutorialGlow = SKShapeNode(circleOfRadius: size / 2 + 5)

        super.init()

        self.name = name

        tutorialGlow.name = "TutorialGlow"
        tutorialGlow.fillColor = .clear
        tutorialGlow.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.24, alpha: 1.0)
        tutorialGlow.lineWidth = 3
        tutorialGlow.glowWidth = 5
        tutorialGlow.zPosition = -1
        tutorialGlow.isHidden = true
        addChild(tutorialGlow)


        let hitArea = SKShapeNode(circleOfRadius: size / 2)

        hitArea.name = name

        hitArea.fillColor = SKColor(red: 0.10, green: 0.28, blue: 0.48, alpha: 0.72)

        hitArea.strokeColor = SKColor(red: 0.34, green: 0.72, blue: 1, alpha: 0.55)

        hitArea.lineWidth = 1.5

        addChild(hitArea)


        let symbolName = direction == .left ? "rotate.left" : "rotate.right"

        let configuration = UIImage.SymbolConfiguration(pointSize: size * 0.44, weight: .semibold)

        if let symbol = UIImage(systemName: symbolName, withConfiguration: configuration)?

            .withTintColor(.white, renderingMode: .alwaysOriginal) {

            let canvasSize = CGSize(width: size, height: size)

            let rendered = UIGraphicsImageRenderer(size: canvasSize).image { _ in

                let origin = CGPoint(

                    x: (canvasSize.width - symbol.size.width) / 2,

                    y: (canvasSize.height - symbol.size.height) / 2

                )

                symbol.draw(at: origin)

            }

            let icon = SKSpriteNode(texture: SKTexture(image: rendered))

            icon.name = name

            icon.size = canvasSize

            icon.zPosition = 2

            addChild(icon)

        }

    }

    func setTutorialHighlighted(_ isHighlighted: Bool) {
        tutorialGlow.isHidden = !isHighlighted
        tutorialGlow.removeAction(forKey: "tutorialGlowPulse")
        tutorialGlow.alpha = 1
        if isHighlighted {
            tutorialGlow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.4, duration: 0.65),
                .fadeAlpha(to: 1.0, duration: 0.65)
            ])), withKey: "tutorialGlowPulse")
        }
    }


    @available(*, unavailable)

    required init?(coder aDecoder: NSCoder) { nil }

}


final class MapButtonNode: SKNode {

    private let background: SKShapeNode

    private let label: SKLabelNode
    private let tutorialGlow: SKShapeNode


    init(title: String, name: String, size: CGSize? = nil, borderless: Bool = false, fontSize: CGFloat = 14) {

        let isEnterMapButton = name == MapNodeName.enterButton.rawValue

        let displayTitle = title

        let resolvedSize = isEnterMapButton
            ? CGSize(width: 160, height: 44)
            : size ?? CGSize(width: max(CGFloat(title.count) * 12 + 28, 64), height: 48)


        background = SKShapeNode(

            rectOf: resolvedSize,

            cornerRadius: isEnterMapButton ? 18 : min(14, resolvedSize.height / 2)

        )

        tutorialGlow = SKShapeNode(
            rectOf: CGSize(width: resolvedSize.width + 10, height: resolvedSize.height + 10),
            cornerRadius: isEnterMapButton ? 21 : min(17, resolvedSize.height / 2 + 3)
        )

        label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

        super.init()

        self.name = name

        isUserInteractionEnabled = false

        tutorialGlow.name = "TutorialGlow"
        tutorialGlow.fillColor = .clear
        tutorialGlow.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.24, alpha: 1.0)
        tutorialGlow.lineWidth = 3
        tutorialGlow.glowWidth = 5
        tutorialGlow.zPosition = -1
        tutorialGlow.isHidden = true
        addChild(tutorialGlow)


        background.name = name


        if isEnterMapButton {

            background.fillColor = SKColor(red: 0.95, green: 0.89, blue: 0.74, alpha: 0.96)

            background.strokeColor = SKColor(red: 0.24, green: 0.19, blue: 0.15, alpha: 1)

            background.lineWidth = 2


            let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)

            if let image = UIImage(systemName: "map.fill", withConfiguration: configuration)?

                .withTintColor(

                    UIColor(red: 0.24, green: 0.19, blue: 0.15, alpha: 1),

                    renderingMode: .alwaysOriginal

                ) {

                let icon = SKSpriteNode(texture: SKTexture(image: image))

                icon.name = name

                icon.size = CGSize(width: 22, height: 22)

                icon.position = CGPoint(x: -62, y: 0)

                icon.zPosition = 1

                addChild(icon)

            }

        } else {

            background.fillColor = borderless
                ? SKColor.black.withAlphaComponent(0.001)
                : SKColor.black.withAlphaComponent(0.68)

            background.strokeColor = borderless ? .clear : .white

            background.lineWidth = borderless ? 0 : 2

        }


        addChild(background)


        label.name = name

        label.text = displayTitle

        label.fontSize = isEnterMapButton ? 13 : (title.count == 1 ? 34 : fontSize)

        label.fontColor = isEnterMapButton
            ? SKColor(red: 0.24, green: 0.19, blue: 0.15, alpha: 1)
            : .white

        label.verticalAlignmentMode = .center

        label.horizontalAlignmentMode = .center

        label.position.x = isEnterMapButton ? 12 : 0

        label.zPosition = 2

        addChild(label)

    }


    func setTitle(_ title: String) { label.text = title }


    func setEnabled(_ isEnabled: Bool) {

        alpha = isEnabled ? 1 : 0.28

    }

    func setTutorialHighlighted(_ isHighlighted: Bool) {
        tutorialGlow.isHidden = !isHighlighted
        tutorialGlow.removeAction(forKey: "tutorialGlowPulse")
        tutorialGlow.alpha = 1
        if isHighlighted {
            tutorialGlow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.4, duration: 0.65),
                .fadeAlpha(to: 1.0, duration: 0.65)
            ])), withKey: "tutorialGlowPulse")
        }
    }


    @available(*, unavailable)

    required init?(coder aDecoder: NSCoder) { nil }

}
