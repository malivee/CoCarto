import SpriteKit
import UIKit

struct MapQuestItem {
    let category: String
    let title: String
    let isCompleted: Bool
}

enum MapTutorialStep: Equatable {
    case selectTile
    case rotateTile(isValid: Bool)
    case openSidebar
    case dragHouse
    case placeHouse(isValid: Bool)
    case dragWell
    case placeWell(isValid: Bool)
    case enterWorld

    var badge: String {
        switch self {
        case .selectTile: return "1"
        case .rotateTile: return "2"
        case .openSidebar: return "3"
        case .dragHouse, .placeHouse: return "4"
        case .dragWell, .placeWell: return "5"
        case .enterWorld: return "6"
        }
    }

    var title: String {
        switch self {
        case .selectTile:
            return "Pilih Ubin"
        case .rotateTile:
            return "Putar Ubin"
        case .openSidebar:
            return "Buka Bangunan"
        case .dragHouse:
            return "Seret Rumah Arthur"
        case .placeHouse(let isValid):
            return isValid ? "Lepaskan di Sini" : "Cari Area Kuning"
        case .dragWell:
            return "Seret Sumur"
        case .placeWell(let isValid):
            return isValid ? "Lepaskan di Sini" : "Cari Area Kuning"
        case .enterWorld:
            return "Masuk ke Desa"
        }
    }

    var subtitle: String {
        switch self {
        case .selectTile:
            return "Ketuk ubin yang menyala."
        case .rotateTile:
            return "Gunakan tombol yang menyala."
        case .openSidebar:
            return "Ketuk tombol yang menyala."
        case .dragHouse:
            return "Ikuti contoh gerak di layar."
        case .placeHouse(let isValid):
            return isValid
                ? "Posisinya sudah tepat."
                : "Geser sampai bingkai hijau."
        case .dragWell:
            return "Ikuti contoh gerak di layar."
        case .placeWell(let isValid):
            return isValid
                ? "Posisinya sudah tepat."
                : "Geser sampai bingkai hijau."
        case .enterWorld:
            return "Ketuk ubin yang menyala dua kali."
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

        let bannerWidth = min(maxWidth, 350)
        let bannerHeight: CGFloat = 54

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

    private let inventoryToggle = MapButtonNode(

        title: "HOUSE ⌄",

        name: MapNodeName.inventoryToggle.rawValue,

        size: CGSize(width: 166, height: 64),

        borderless: false,

        fontSize: 18

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

    private let selectionTray = SKShapeNode()

    private let selectionControls = SKNode()
    private let objectStatus = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let placeObjectButton = MapButtonNode(title: "Pasang", name: MapNodeName.confirmButton.rawValue)
    private let cancelObjectButton = MapButtonNode(title: "Batal", name: MapNodeName.cancelButton.rawValue)
    private let tutorialBanner = TutorialBannerNode()
    private var inventoryItemNodes: [BuildingObjectKind: SKNode] = [:]

    private let inventoryKinds: [BuildingObjectKind]

//    private let inventoryItems = ["House", "Workshop", "Farm", "Market", "Bridge", "Tower"]

    private let itemHeight: CGFloat = 58

    private let panelSize = CGSize(width: 166, height: 356)


    init(inventoryKinds: [BuildingObjectKind]) {

        self.inventoryKinds = inventoryKinds

        super.init()

        name = MapNodeName.hud.rawValue

        zPosition = 600

        configureInventory()

        configureSelectionControls()

        configureQuestTracker()

        configureTutorialNodes()

        addChild(inventoryToggle)

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


        inventoryToggle.position = CGPoint(x: cameraCenter.x - halfWidth + sideInset + 83, y: topY)

        inventoryToggle.setTitle(inventoryExpanded ? "TUTUP ⌃" : "BANGUNAN ⌄")

        inventoryPanel.position = CGPoint(

            x: cameraCenter.x - halfWidth + sideInset + panelSize.width / 2,

            y: topY - 32 - panelSize.height / 2

        )

        inventoryPanel.isHidden = !inventoryExpanded

        questPanel.position = CGPoint(
            x: cameraCenter.x + halfWidth - sideInset - 126,
            y: topY - 22
        )

        questPanel.update(with: Array(questItems.prefix(2)))
        questPanel.isHidden = (tutorialStep != nil)

        // Keep tutorial copy inside the top HUD row, away from the inventory
        // list and the bottom placement controls.
        let bannerY = topY - 78
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
            let statusText = isValid ? "● Siap Dipasang" : "○ " + (objectResult?.message ?? "Pindahkan ke tanah desa")
            objectStatus.text = "\(definition.title) (\(objectPreview?.mapDimensions.width ?? definition.mapWidth)×\(objectPreview?.mapDimensions.height ?? definition.mapHeight)) · \(statusText)"
            objectStatus.fontColor = isValid ? SKColor(red: 0.4, green: 0.95, blue: 0.5, alpha: 1.0) : SKColor(red: 0.98, green: 0.75, blue: 0.35, alpha: 1.0)
            objectStatus.position.y = 30

            placeObjectButton.position = CGPoint(x: 75, y: -25)
            cancelObjectButton.position = CGPoint(x: -75, y: -25)
            placeObjectButton.setTitle("✓ Pasang")
            cancelObjectButton.setTitle("✕ Batal")
            placeObjectButton.isHidden = false
            cancelObjectButton.isHidden = false
            placeObjectButton.setEnabled(isValid)
        } else if preview != nil {
            // TILE PIECES: ROTATION ACTIVE!
            selectionControls.isHidden = false
            selectionControls.position.y = 44
            selectionControls.setScale(1.0)

            objectStatus.isHidden = false
            let isValid = preview?.isValid == true
            let alignText = isValid ? "● Posisi Cocok" : "○ Tepi Belum Sesuai"
            objectStatus.text = "Ubin Peta · \(alignText) · Putar dengan ⟲ / ⟳"
            objectStatus.fontColor = isValid ? SKColor(red: 0.4, green: 0.95, blue: 0.5, alpha: 1.0) : SKColor(red: 0.98, green: 0.75, blue: 0.35, alpha: 1.0)
            objectStatus.position.y = 94

            placeObjectButton.position = CGPoint(x: 66, y: -65)
            cancelObjectButton.position = CGPoint(x: -66, y: -65)
            placeObjectButton.setTitle("✓ Selesai")
            cancelObjectButton.setTitle("✕ Batal")
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

    }

    private func configureTutorialNodes() {
        addChild(tutorialBanner)
    }

    private func updateTutorialHighlights(for step: MapTutorialStep?) {
        inventoryToggle.setTutorialHighlighted(step == .openSidebar)
        rotateLeftButton.setTutorialHighlighted(false)
        rotateRightButton.setTutorialHighlighted(false)
        placeObjectButton.setTutorialHighlighted(false)
        inventoryItemNodes.values.forEach {
            $0.childNode(withName: "TutorialGlow")?.removeFromParent()
        }

        switch step {
        case .rotateTile:
            rotateLeftButton.setTutorialHighlighted(true)
            rotateRightButton.setTutorialHighlighted(true)
        case .dragHouse:
            addTutorialGlow(to: inventoryItemNodes[.arthurHouse])
        case .dragWell:
            addTutorialGlow(to: inventoryItemNodes[.well])
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

        inventoryPanel.fillColor = SKColor(red: 0.04, green: 0.06, blue: 0.07, alpha: 0.78)

        inventoryPanel.strokeColor = .clear

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


        for (index, kind) in inventoryKinds.enumerated() {

            let title = BuildingObjectCatalog.definition(for: kind).title

            let item = makeInventoryItem(title: title, index: index)

            item.position = CGPoint(x: 0, y: panelSize.height / 2 - 10 - itemHeight / 2 - CGFloat(index) * itemHeight)

            inventoryContent.addChild(item)
            inventoryItemNodes[kind] = item

        }

    }


    private func makeInventoryItem(title: String, index: Int) -> SKNode {
        let root = SKNode()
        root.name = MapNodeName.inventoryItem.rawValue
        root.userData = ["inventoryIndex": index]

        let kind = inventoryKinds[index]
        let definition = BuildingObjectCatalog.definition(for: kind)

        let hitArea = SKShapeNode(rectOf: CGSize(width: panelSize.width - 12, height: itemHeight - 2))
        hitArea.name = MapNodeName.inventoryItem.rawValue
        hitArea.fillColor = SKColor.white.withAlphaComponent(0.001)
        hitArea.strokeColor = .clear
        root.addChild(hitArea)

        let icon = SKShapeNode(circleOfRadius: 13)
        icon.position.x = -44
        icon.fillColor = index == 0 ? .systemYellow : SKColor.white.withAlphaComponent(0.18)
        icon.strokeColor = .clear
        root.addChild(icon)

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = title
        label.fontSize = 14
        label.fontColor = index == 0 ? .systemGreen : SKColor.white.withAlphaComponent(0.58)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position.x = -20
        root.addChild(label)

        let dimensions = SKLabelNode(fontNamed: "AvenirNext-Regular")
        dimensions.text = "\(definition.mapWidth)×\(definition.mapHeight)"
        dimensions.fontSize = 10
        dimensions.fontColor = .lightGray
        dimensions.horizontalAlignmentMode = .left
        dimensions.position = CGPoint(x: -20, y: -20)
        root.addChild(dimensions)

        if index > 0 {
            let soon = SKLabelNode(fontNamed: "AvenirNext-Regular")
            soon.text = "soon"
            soon.fontSize = 9
            soon.fontColor = SKColor.white.withAlphaComponent(0.28)
            soon.horizontalAlignmentMode = .right
            soon.position = CGPoint(x: 55, y: -15)
            root.addChild(soon)
        }

        return root
    }


    private func configureSelectionControls() {

        selectionTray.fillColor = SKColor(red: 0.035, green: 0.10, blue: 0.19, alpha: 1)

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
        objectStatus.fontSize = 12
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

        let displayTitle = isEnterMapButton ? "MAP" : title

        let resolvedSize = isEnterMapButton
            ? CGSize(width: 112, height: 50)
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

                icon.position = CGPoint(x: -27, y: 0)

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

        label.fontSize = isEnterMapButton ? 16 : (title.count == 1 ? 34 : fontSize)

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
