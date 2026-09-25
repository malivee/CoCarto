import SpriteKit
import UIKit

final class MapHUDNode: SKNode {
    private let inventoryToggle = MapButtonNode(
        title: "HOUSE ⌄",
        name: MapNodeName.inventoryToggle.rawValue,
        size: CGSize(width: 166, height: 64),
        borderless: false,
        fontSize: 18
    )
    private let exitButton = MapButtonNode(
        title: "×",
        name: MapNodeName.exitButton.rawValue,
        size: CGSize(width: 58, height: 58),
        borderless: true
    )
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

    private let inventoryItems = BuildingObjectKind.allCases.map { BuildingObjectCatalog.definition(for: $0).title }
    private let itemHeight: CGFloat = 58
    private let panelSize = CGSize(width: 166, height: 356)

    override init() {
        super.init()
        name = MapNodeName.hud.rawValue
        zPosition = 600
        configureInventory()
        configureSelectionControls()
        addChild(inventoryToggle)
        addChild(exitButton)
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
        objectResult: BuildingPlacementResult? = nil
    ) {
        let cameraScale: CGFloat = 1.35
        let halfWidth = sceneSize.width * cameraScale / 2
        let halfHeight = sceneSize.height * cameraScale / 2
        let sideInset: CGFloat = 14
        let topY = cameraCenter.y + halfHeight - 116

        inventoryToggle.position = CGPoint(x: cameraCenter.x - halfWidth + sideInset + 83, y: topY)
        inventoryToggle.setTitle("\(inventorySelectionTitle.uppercased()) \(inventoryExpanded ? "⌃" : "⌄")")
        inventoryPanel.position = CGPoint(
            x: cameraCenter.x - halfWidth + sideInset + panelSize.width / 2,
            y: topY - 32 - panelSize.height / 2
        )
        inventoryPanel.isHidden = !inventoryExpanded
        exitButton.position = CGPoint(x: cameraCenter.x + halfWidth - sideInset - 26, y: topY)

        let trayHeight: CGFloat = 216
        let trayY = cameraCenter.y - halfHeight + trayHeight / 2
        selectionTray.path = CGPath(
            rect: CGRect(x: -halfWidth, y: -trayHeight / 2, width: halfWidth * 2, height: trayHeight),
            transform: nil
        )
        selectionTray.position = CGPoint(x: cameraCenter.x, y: trayY)
        selectionTray.isHidden = preview == nil && selectedObjectKind == nil
        selectionControls.position.y = selectedObjectKind == nil ? 44 : 20
        selectionControls.setScale(selectedObjectKind == nil ? 1 : 0.75)
        objectStatus.isHidden = selectedObjectKind == nil
        objectStatus.preferredMaxLayoutWidth = halfWidth * 2 - 30
        placeObjectButton.isHidden = selectedObjectKind == nil
        cancelObjectButton.isHidden = selectedObjectKind == nil
        placeObjectButton.setEnabled(objectResult == .valid)
        if let selectedObjectKind {
            let definition = BuildingObjectCatalog.definition(for: selectedObjectKind)
            objectStatus.text = "\(definition.title) \(objectPreview?.mapDimensions.width ?? definition.mapWidth)×\(objectPreview?.mapDimensions.height ?? definition.mapHeight) · \(objectResult?.message ?? "Seret ke village soil")"
        }
        if animateSelection, preview != nil {
            selectionTray.position.y = trayY - trayHeight
            let reveal = SKAction.moveTo(y: trayY, duration: 0.11)
            reveal.timingMode = .easeOut
            selectionTray.run(reveal, withKey: "revealSelectionTray")
        }
        inventoryContent.position.y = inventoryScrollOffset
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

        for (index, title) in inventoryItems.enumerated() {
            let item = makeInventoryItem(title: title, index: index)
            item.position = CGPoint(x: 0, y: panelSize.height / 2 - 10 - itemHeight / 2 - CGFloat(index) * itemHeight)
            inventoryContent.addChild(item)
        }
    }

    private func makeInventoryItem(title: String, index: Int) -> SKNode {
        let root = SKNode()
        root.name = MapNodeName.inventoryItem.rawValue
        root.userData = ["inventoryIndex": index]

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
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position.x = -20
        root.addChild(label)

        let definition = BuildingObjectCatalog.definition(for: BuildingObjectKind.allCases[index])
        let dimensions = SKLabelNode(fontNamed: "AvenirNext-Regular")
        dimensions.text = "\(definition.mapWidth)×\(definition.mapHeight)"
        dimensions.fontSize = 10
        dimensions.fontColor = .lightGray
        dimensions.horizontalAlignmentMode = .left
        dimensions.position = CGPoint(x: -20, y: -20)
        root.addChild(dimensions)
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
    init(direction: RotationButtonDirection, name: String, size: CGFloat) {
        super.init()
        self.name = name

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

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { nil }
}

final class MapButtonNode: SKNode {
    private let background: SKShapeNode
    private let label: SKLabelNode

    init(title: String, name: String, size: CGSize? = nil, borderless: Bool = false, fontSize: CGFloat = 14) {
        let resolvedSize = size ?? CGSize(width: max(CGFloat(title.count) * 12 + 28, 64), height: 48)
        background = SKShapeNode(rectOf: resolvedSize, cornerRadius: min(14, resolvedSize.height / 2))
        label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        super.init()
        self.name = name
        isUserInteractionEnabled = false

        background.name = name
        background.fillColor = borderless ? SKColor.black.withAlphaComponent(0.001) : SKColor.black.withAlphaComponent(0.68)
        background.strokeColor = borderless ? .clear : .white
        background.lineWidth = borderless ? 0 : 2
        addChild(background)

        label.name = name
        label.text = title
        label.fontSize = title.count == 1 ? 34 : fontSize
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
    }

    func setTitle(_ title: String) { label.text = title }

    func setEnabled(_ isEnabled: Bool) {
        alpha = isEnabled ? 1 : 0.28
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { nil }
}
