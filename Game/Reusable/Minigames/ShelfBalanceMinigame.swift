// File description: ShelfBalanceMinigame.swift
// Minigame Component "Event 1: Helping Mrs. Mara" (Shelf Leg Balance & Precision Brick Wedge QTE).
// Visual & Architectural Consistency:
// - SpriteKit Node (SKNode) based, consistent with ItemSortingMinigame & SeedSortingMinigame.
// - Displays Mrs. Mara's narrative dialog using SpeechBubbleNode (artistic crayon style).
// - Grounded shelf: Left leg on a stone paver, right leg sinking into the mud, and a brick wedge
//   supporting the right leg exactly at ground level.
// - Mechanics: When lifted, the shelf STAYS lifted. The player balances it using Gyro,
//   then performs a Precision Tap on the DBD slider in the green zone to slide the brick wedge in.

import SpriteKit
import CoreMotion
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration

public struct ShelfBalanceConfig: Sendable {
    public var balanceTolerance: CGFloat    // Straight tilt tolerance (radians)
    public var failAngle: CGFloat           // Tilt limit before pots fall
    public var dbdSliderSpeed: CGFloat      // Brick slider speed
    public var dbdTargetStart: CGFloat      // Green zone start (0.0 - 1.0)
    public var dbdTargetEnd: CGFloat        // Green zone end (0.0 - 1.0)
    public var headingText: String
    
    public init(
        balanceTolerance: CGFloat = 0.08,   // ~4.5 degrees
        failAngle: CGFloat = 0.40,          // ~23 degrees
        dbdSliderSpeed: CGFloat = 1.35,
        dbdTargetStart: CGFloat = 0.60,
        dbdTargetEnd: CGFloat = 0.80,
        headingText: String = "Help Mrs. Mara: WEDGE THE SHELF"
    ) {
        self.balanceTolerance = balanceTolerance
        self.failAngle = failAngle
        self.dbdSliderSpeed = dbdSliderSpeed
        self.dbdTargetStart = dbdTargetStart
        self.dbdTargetEnd = dbdTargetEnd
        self.headingText = headingText
    }
}

// MARK: - SpriteKit Node (Consistent with ItemSorting & SeedSorting)

public final class ShelfBalanceMinigameNode: SKNode {
    
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?
    
    private let config: ShelfBalanceConfig
    private var isRunning: Bool = false
    private var isCompleted: Bool = false
    
    // Physics & Lift State
    private let motionManager = CMMotionManager()
    private var shelfAngle: CGFloat = 0.17 // Initially sinking ~9.8 degrees into the mud
    private var simulatedTilt: CGFloat = 0.0
    private var isShelfLifted: Bool = false // Once lifted, stays in the lifted position
    private var isBalanced: Bool = false
    private var isWedgePlaced: Bool = false
    private var hammerTaps: Int = 0 // 2 hammer taps to lock it tight
    
    // DBD Slider State
    private var sliderProgress: CGFloat = 0.0
    private var sliderDirection: CGFloat = 1.0
    private var lastUpdateTime: TimeInterval = 0
    
    // Hierarchy nodes
    private let container = SKNode()
    private let backdrop = SKSpriteNode()
    private let vignette = SKShapeNode()
    
    private let cottageWallNode = SKNode()
    
    // Ground & Mud Elements (Grounded)
    private let groundNode = SKNode()
    private let groundForegroundNode = SKNode()
    private let sunkenPitNode = SKShapeNode()
    private let stonePaverNode = SKShapeNode()
    
    // Shelf & Furniture Nodes
    private let shelfPivotNode = SKNode() // Pivot point at the base of the left leg
    private let shelfBodyNode = SKNode()
    private let leftLegNode = SKShapeNode()
    private let rightLegNode = SKShapeNode()
    private let shelfPlankNode = SKShapeNode()
    private let brickWedgeNode = SKShapeNode() // Brick wedge under the right leg
    
    // Artisan Clay Pots (3D Shaded)
    private let pot1Node = SKNode()
    private let pot2Node = SKNode()
    private let pot3Node = SKNode()
    
    // Waterpass Level Indicator
    private let waterpassNode = SKNode()
    private let waterpassBubble = SKShapeNode()
    private let waterpassGlow = SKShapeNode()
    
    // DBD QTE Slider Track
    private let dbdTrackNode = SKNode()
    private let dbdCursorNode = SKShapeNode()
    private let dbdTargetZoneNode = SKShapeNode()
    private let dbdTrackWidth: CGFloat = 260
    
    // Hammer QTE Visual Indicator (Non-text)
    private let hammerPromptNode = SKNode()
    private let hammerPip1 = SKShapeNode()
    private let hammerPip2 = SKShapeNode()
    
    // Minimalist Top HUD (Ultra-minimal: Only a small "WEDGE SHELF" badge and close button)
    private let headerBar = SKNode()
    private let headerTitleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    // Speech Bubble Dialog (Mrs. Mara's short narrative)
    private var activeSpeechBubble: SpeechBubbleNode?
    
    public init(config: ShelfBalanceConfig = ShelfBalanceConfig()) {
        self.config = config
        super.init()
        isUserInteractionEnabled = true
        zPosition = 800
        buildVisuals()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Setup (Outside of the House & Grounded Shelf)
    
    private func buildVisuals() {
        addChild(container)
        
        // 1. Outside Mrs. Mara's Cottage (Sky, Wooden & Stone Walls)
        buildOutsideCottageBackground()
        
        // 2. Mrs. Mara's Yard Ground (Straight horizontal ground line)
        buildGroundAndPavers()
        
        // 3. Village Teak Wooden Shelf & Clay Pots (Standing straight into the ground)
        buildArtisanShelf()
        
        // 4. Sleek Brass Spirit Level (Waterpass)
        buildWaterpass()
        
        // 5. DBD QTE Slider Track
        buildDBDTrack()
        
        // 6. Minimalist Header HUD (Clean & Tidy)
        buildMinimalHUD()
        
        // Set initial orientation sinking into the mud
        shelfPivotNode.zRotation = -shelfAngle
    }
    
    private func buildOutsideCottageBackground() {
        // 1. Open outdoor daylight sky
        let sky = SKSpriteNode(color: SKColor(red: 0.55, green: 0.74, blue: 0.86, alpha: 1.0), size: CGSize(width: 3000, height: 3000))
        sky.zPosition = -50
        container.addChild(sky)
        
        // Warm sun glow in the yard
        let sunGlow = SKShapeNode(circleOfRadius: 180)
        sunGlow.position = CGPoint(x: 130, y: 280)
        sunGlow.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.78, alpha: 0.40)
        sunGlow.strokeColor = .clear
        sunGlow.blendMode = .add
        sunGlow.zPosition = -45
        container.addChild(sunGlow)
        
        let sunCore = SKShapeNode(circleOfRadius: 38)
        sunCore.position = CGPoint(x: 130, y: 280)
        sunCore.fillColor = SKColor(red: 1.0, green: 0.98, blue: 0.88, alpha: 0.95)
        sunCore.strokeColor = SKColor(red: 1.0, green: 0.92, blue: 0.60, alpha: 0.5)
        sunCore.lineWidth = 4.0
        sunCore.zPosition = -44
        container.addChild(sunCore)
        
        // Soft sunbeams penetrating the yard
        for i in 0..<3 {
            let beam = SKShapeNode()
            let bp = CGMutablePath()
            let bx: CGFloat = 130 + CGFloat(i * 45)
            bp.move(to: CGPoint(x: bx - 15, y: 280))
            bp.addLine(to: CGPoint(x: bx - 140, y: -120))
            bp.addLine(to: CGPoint(x: bx - 70, y: -120))
            bp.addLine(to: CGPoint(x: bx + 25, y: 280))
            bp.closeSubpath()
            beam.path = bp
            beam.fillColor = SKColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 0.08)
            beam.strokeColor = .clear
            beam.blendMode = .add
            beam.zPosition = -43
            container.addChild(beam)
        }
        
        // Soft white drifting clouds in the sky
        createCloud(at: CGPoint(x: -80, y: 310), scale: 0.9)
        createCloud(at: CGPoint(x: 120, y: 230), scale: 0.7)
        createCloud(at: CGPoint(x: -160, y: 210), scale: 0.6)
        
        // 2. Distant village mountain silhouettes
        let distantHills = SKShapeNode()
        let dhPath = CGMutablePath()
        dhPath.move(to: CGPoint(x: -600, y: -120))
        dhPath.addQuadCurve(to: CGPoint(x: -40, y: 20), control: CGPoint(x: -300, y: 70))
        dhPath.addQuadCurve(to: CGPoint(x: 600, y: -40), control: CGPoint(x: 250, y: 60))
        dhPath.addLine(to: CGPoint(x: 600, y: -120))
        dhPath.closeSubpath()
        distantHills.path = dhPath
        distantHills.fillColor = SKColor(red: 0.46, green: 0.62, blue: 0.58, alpha: 0.65)
        distantHills.strokeColor = .clear
        distantHills.zPosition = -35
        container.addChild(distantHills)
        
        // Closer green village hills
        let midHills = SKShapeNode()
        let mhPath = CGMutablePath()
        mhPath.move(to: CGPoint(x: -600, y: -120))
        mhPath.addQuadCurve(to: CGPoint(x: 100, y: -20), control: CGPoint(x: -180, y: 30))
        mhPath.addQuadCurve(to: CGPoint(x: 600, y: -60), control: CGPoint(x: 380, y: 15))
        mhPath.addLine(to: CGPoint(x: 600, y: -120))
        mhPath.closeSubpath()
        midHills.path = mhPath
        midHills.fillColor = SKColor(red: 0.35, green: 0.52, blue: 0.30, alpha: 0.85)
        midHills.strokeColor = .clear
        midHills.zPosition = -30
        container.addChild(midHills)
        
        // Distant village trees
        for tx in [20.0, 75.0, 160.0, 210.0] {
            let tree = createDistantTree(height: CGFloat.random(in: 28...38))
            tree.position = CGPoint(x: tx, y: -25)
            tree.zPosition = -28
            container.addChild(tree)
        }
        
        // 3. Outdoor Yard & Village Well Lore ("In Mrs. Mara's yard near the village well")
        buildOutdoorYardProps()
        
        // 4. Cottage Exterior Wall on the Left
        buildLeftCottageExterior()
    }
    
    private func createCloud(at pos: CGPoint, scale: CGFloat) {
        let cloud = SKNode()
        cloud.position = pos
        cloud.setScale(scale)
        cloud.zPosition = -40
        container.addChild(cloud)
        
        let cColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85)
        let puff1 = SKShapeNode(ellipseOf: CGSize(width: 70, height: 32))
        puff1.fillColor = cColor
        puff1.strokeColor = .clear
        cloud.addChild(puff1)
        
        let puff2 = SKShapeNode(circleOfRadius: 20)
        puff2.position = CGPoint(x: -18, y: 10)
        puff2.fillColor = cColor
        puff2.strokeColor = .clear
        cloud.addChild(puff2)
        
        let puff3 = SKShapeNode(circleOfRadius: 16)
        puff3.position = CGPoint(x: 18, y: 8)
        puff3.fillColor = cColor
        puff3.strokeColor = .clear
        cloud.addChild(puff3)
        
        // Cloud drifting animation
        let floatAction = SKAction.sequence([
            .moveBy(x: 16, y: 0, duration: 4.5),
            .moveBy(x: -16, y: 0, duration: 4.5)
        ])
        cloud.run(.repeatForever(floatAction))
    }
    
    private func createDistantTree(height: CGFloat) -> SKNode {
        let tree = SKNode()
        let trunk = SKShapeNode(rectOf: CGSize(width: 4, height: height * 0.4))
        trunk.position = CGPoint(x: 0, y: height * 0.2)
        trunk.fillColor = SKColor(red: 0.32, green: 0.22, blue: 0.14, alpha: 0.9)
        trunk.strokeColor = .clear
        tree.addChild(trunk)
        
        let crown = SKShapeNode(circleOfRadius: height * 0.45)
        crown.position = CGPoint(x: 0, y: height * 0.65)
        crown.fillColor = SKColor(red: 0.28, green: 0.46, blue: 0.24, alpha: 0.95)
        crown.strokeColor = .clear
        tree.addChild(crown)
        return tree
    }
    
    private func buildOutdoorYardProps() {
        let yardNode = SKNode()
        yardNode.position = CGPoint(x: 0, y: -120)
        yardNode.zPosition = -20
        container.addChild(yardNode)
        
        // Rustic village wooden fence behind the shelf
        let fenceStartX: CGFloat = -40
        let fenceEndX: CGFloat = 260
        let fenceRail1 = SKShapeNode(rectOf: CGSize(width: fenceEndX - fenceStartX, height: 6), cornerRadius: 2)
        fenceRail1.position = CGPoint(x: (fenceStartX + fenceEndX)/2, y: 46)
        fenceRail1.fillColor = SKColor(red: 0.44, green: 0.30, blue: 0.18, alpha: 0.9)
        fenceRail1.strokeColor = SKColor(red: 0.26, green: 0.16, blue: 0.08, alpha: 1.0)
        fenceRail1.lineWidth = 1.0
        yardNode.addChild(fenceRail1)
        
        let fenceRail2 = SKShapeNode(rectOf: CGSize(width: fenceEndX - fenceStartX, height: 6), cornerRadius: 2)
        fenceRail2.position = CGPoint(x: (fenceStartX + fenceEndX)/2, y: 24)
        fenceRail2.fillColor = SKColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 0.9)
        fenceRail2.strokeColor = SKColor(red: 0.24, green: 0.14, blue: 0.08, alpha: 1.0)
        fenceRail2.lineWidth = 1.0
        yardNode.addChild(fenceRail2)
        
        for fx in stride(from: fenceStartX, through: fenceEndX, by: 45) {
            let post = SKShapeNode(rectOf: CGSize(width: 8, height: 60), cornerRadius: 2)
            post.position = CGPoint(x: fx, y: 30)
            post.fillColor = SKColor(red: 0.38, green: 0.25, blue: 0.15, alpha: 1.0)
            post.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.07, alpha: 1.0)
            post.lineWidth = 1.0
            yardNode.addChild(post)
        }
        
        // VILLAGE WELL (Lore: "In Mrs. Mara's yard near the village well")
        let wellX: CGFloat = 145
        let wellBase = SKShapeNode(rectOf: CGSize(width: 54, height: 38), cornerRadius: 5)
        wellBase.position = CGPoint(x: wellX, y: 19)
        wellBase.fillColor = SKColor(red: 0.45, green: 0.42, blue: 0.38, alpha: 1.0)
        wellBase.strokeColor = SKColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1.0)
        wellBase.lineWidth = 2.0
        yardNode.addChild(wellBase)
        
        // Round well stones
        for si in -2...2 {
            let stone = SKShapeNode(rectOf: CGSize(width: 14, height: 8), cornerRadius: 2)
            stone.position = CGPoint(x: wellX + CGFloat(si) * 10, y: 22)
            stone.fillColor = SKColor(red: 0.52, green: 0.48, blue: 0.44, alpha: 1.0)
            stone.strokeColor = SKColor(red: 0.28, green: 0.24, blue: 0.20, alpha: 0.8)
            stone.lineWidth = 0.8
            yardNode.addChild(stone)
        }
        
        // Wooden well posts
        for px in [wellX - 22, wellX + 22] {
            let post = SKShapeNode(rectOf: CGSize(width: 5, height: 50), cornerRadius: 1)
            post.position = CGPoint(x: px, y: 55)
            post.fillColor = SKColor(red: 0.36, green: 0.23, blue: 0.13, alpha: 1.0)
            post.strokeColor = SKColor(red: 0.20, green: 0.11, blue: 0.06, alpha: 1.0)
            post.lineWidth = 1.0
            yardNode.addChild(post)
        }
        
        // Well tile roof
        let wellRoofPath = CGMutablePath()
        wellRoofPath.move(to: CGPoint(x: wellX - 32, y: 75))
        wellRoofPath.addLine(to: CGPoint(x: wellX, y: 92))
        wellRoofPath.addLine(to: CGPoint(x: wellX + 32, y: 75))
        wellRoofPath.closeSubpath()
        let wellRoof = SKShapeNode(path: wellRoofPath)
        wellRoof.fillColor = SKColor(red: 0.70, green: 0.32, blue: 0.18, alpha: 1.0)
        wellRoof.strokeColor = SKColor(red: 0.42, green: 0.16, blue: 0.08, alpha: 1.0)
        wellRoof.lineWidth = 1.5
        yardNode.addChild(wellRoof)
        
        // Wooden well bucket
        let bucket = SKShapeNode(rectOf: CGSize(width: 12, height: 14), cornerRadius: 2)
        bucket.position = CGPoint(x: wellX, y: 52)
        bucket.fillColor = SKColor(red: 0.48, green: 0.34, blue: 0.20, alpha: 1.0)
        bucket.strokeColor = SKColor(red: 0.26, green: 0.16, blue: 0.08, alpha: 1.0)
        bucket.lineWidth = 1.0
        yardNode.addChild(bucket)
        
        // Mrs. Mara's clay water barrel / pottery vat near the well
        let barrel = SKShapeNode(rectOf: CGSize(width: 22, height: 28), cornerRadius: 4)
        barrel.position = CGPoint(x: wellX - 38, y: 14)
        barrel.fillColor = SKColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 1.0)
        barrel.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.07, alpha: 1.0)
        barrel.lineWidth = 1.5
        yardNode.addChild(barrel)
        
        // Drying clay pots in the outdoor yard
        let dryPot1 = createClayPot(width: 24, height: 28, color: SKColor(red: 0.65, green: 0.40, blue: 0.24, alpha: 0.95))
        dryPot1.position = CGPoint(x: -30, y: 0)
        yardNode.addChild(dryPot1)
        
        let dryPot2 = createClayPot(width: 20, height: 22, color: SKColor(red: 0.58, green: 0.36, blue: 0.20, alpha: 0.95))
        dryPot2.position = CGPoint(x: -12, y: 0)
        yardNode.addChild(dryPot2)
    }
    
    private func buildLeftCottageExterior() {
        cottageWallNode.position = CGPoint(x: -190, y: 70)
        cottageWallNode.zPosition = -15
        container.addChild(cottageWallNode)
        
        let wallW: CGFloat = 160
        let wallH: CGFloat = 380
        
        // Cottage exterior plaster wall
        let wallRect = CGRect(x: -wallW/2, y: -wallH/2, width: wallW, height: wallH)
        let wall = SKShapeNode(rect: wallRect)
        wall.fillColor = SKColor(red: 0.88, green: 0.85, blue: 0.79, alpha: 1.0)
        wall.strokeColor = SKColor(red: 0.38, green: 0.26, blue: 0.16, alpha: 1.0)
        wall.lineWidth = 2.5
        cottageWallNode.addChild(wall)
        
        // River stone foundation below the wall
        let stoneBaseH: CGFloat = 55
        let stoneBase = SKShapeNode(rect: CGRect(x: -wallW/2, y: -wallH/2, width: wallW, height: stoneBaseH))
        stoneBase.fillColor = SKColor(red: 0.48, green: 0.44, blue: 0.40, alpha: 1.0)
        stoneBase.strokeColor = SKColor(red: 0.28, green: 0.24, blue: 0.20, alpha: 1.0)
        stoneBase.lineWidth = 2.0
        cottageWallNode.addChild(stoneBase)
        
        // Stone lines on the foundation
        for bx in [-55, -20, 15, 50] {
            let stoneLine = SKShapeNode(rectOf: CGSize(width: 28, height: 14), cornerRadius: 3)
            stoneLine.position = CGPoint(x: CGFloat(bx), y: -wallH/2 + 26)
            stoneLine.fillColor = SKColor(red: 0.55, green: 0.51, blue: 0.46, alpha: 1.0)
            stoneLine.strokeColor = SKColor(red: 0.32, green: 0.28, blue: 0.24, alpha: 0.8)
            stoneLine.lineWidth = 1.0
            cottageWallNode.addChild(stoneLine)
        }
        
        // Vertical timber framing of the wall
        for bx in [-wallW/2 + 6, wallW/2 - 6] {
            let beam = SKShapeNode(rectOf: CGSize(width: 14, height: wallH))
            beam.position = CGPoint(x: bx, y: 0)
            beam.fillColor = SKColor(red: 0.40, green: 0.26, blue: 0.15, alpha: 1.0)
            beam.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.07, alpha: 1.0)
            beam.lineWidth = 1.5
            cottageWallNode.addChild(beam)
        }
        
        // Horizontal timber beam
        let hBeam = SKShapeNode(rectOf: CGSize(width: wallW, height: 12))
        hBeam.position = CGPoint(x: 0, y: -wallH/2 + stoneBaseH)
        hBeam.fillColor = SKColor(red: 0.36, green: 0.23, blue: 0.13, alpha: 1.0)
        hBeam.strokeColor = SKColor(red: 0.20, green: 0.11, blue: 0.06, alpha: 1.0)
        hBeam.lineWidth = 1.5
        cottageWallNode.addChild(hBeam)
        
        // Exterior wooden window with shutters & blooming flower box
        let winNode = SKNode()
        winNode.position = CGPoint(x: 10, y: 25)
        cottageWallNode.addChild(winNode)
        
        let winFrame = SKShapeNode(rectOf: CGSize(width: 48, height: 56), cornerRadius: 4)
        winFrame.fillColor = SKColor(red: 0.32, green: 0.20, blue: 0.12, alpha: 1.0)
        winFrame.strokeColor = SKColor(red: 0.18, green: 0.10, blue: 0.05, alpha: 1.0)
        winFrame.lineWidth = 2.0
        winNode.addChild(winFrame)
        
        let winGlass = SKShapeNode(rectOf: CGSize(width: 38, height: 46))
        winGlass.fillColor = SKColor(red: 0.22, green: 0.36, blue: 0.44, alpha: 0.85)
        winGlass.strokeColor = SKColor(red: 0.85, green: 0.75, blue: 0.50, alpha: 0.5)
        winGlass.lineWidth = 1.0
        winNode.addChild(winGlass)
        
        // Wooden exterior shutters
        let leftShutter = SKShapeNode(rectOf: CGSize(width: 14, height: 56), cornerRadius: 2)
        leftShutter.position = CGPoint(x: -30, y: 0)
        leftShutter.fillColor = SKColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 1.0)
        leftShutter.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.07, alpha: 1.0)
        leftShutter.lineWidth = 1.2
        winNode.addChild(leftShutter)
        
        let rightShutter = SKShapeNode(rectOf: CGSize(width: 14, height: 56), cornerRadius: 2)
        rightShutter.position = CGPoint(x: 30, y: 0)
        rightShutter.fillColor = SKColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 1.0)
        rightShutter.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.07, alpha: 1.0)
        rightShutter.lineWidth = 1.2
        winNode.addChild(rightShutter)
        
        // Blooming flower box outside the window
        let flowerBox = SKShapeNode(rectOf: CGSize(width: 56, height: 12), cornerRadius: 2)
        flowerBox.position = CGPoint(x: 0, y: -33)
        flowerBox.fillColor = SKColor(red: 0.46, green: 0.30, blue: 0.17, alpha: 1.0)
        flowerBox.strokeColor = SKColor(red: 0.24, green: 0.14, blue: 0.08, alpha: 1.0)
        flowerBox.lineWidth = 1.5
        winNode.addChild(flowerBox)
        
        for fi in -3...3 {
            let flower = SKShapeNode(circleOfRadius: 3.0)
            flower.position = CGPoint(x: CGFloat(fi) * 7.5, y: -26)
            flower.fillColor = fi % 2 == 0 ? SKColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1.0) : SKColor(red: 0.98, green: 0.84, blue: 0.32, alpha: 1.0)
            flower.strokeColor = .clear
            winNode.addChild(flower)
        }
        
        // Antique iron wall lantern
        let lantern = SKShapeNode(rectOf: CGSize(width: 12, height: 18), cornerRadius: 2)
        lantern.position = CGPoint(x: wallW/2 + 16, y: 70)
        lantern.fillColor = SKColor(red: 0.98, green: 0.88, blue: 0.50, alpha: 0.85)
        lantern.strokeColor = SKColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 1.0)
        lantern.lineWidth = 1.5
        cottageWallNode.addChild(lantern)
        
        // Sloping terracotta tile roof eaves
        let eavesPath = CGMutablePath()
        eavesPath.move(to: CGPoint(x: -wallW/2 - 15, y: wallH/2 + 25))
        eavesPath.addLine(to: CGPoint(x: wallW/2 + 25, y: wallH/2 + 35))
        eavesPath.addLine(to: CGPoint(x: wallW/2 + 25, y: wallH/2 + 55))
        eavesPath.addLine(to: CGPoint(x: -wallW/2 - 15, y: wallH/2 + 5))
        eavesPath.closeSubpath()
        let roofEaves = SKShapeNode(path: eavesPath)
        roofEaves.fillColor = SKColor(red: 0.72, green: 0.34, blue: 0.20, alpha: 1.0)
        roofEaves.strokeColor = SKColor(red: 0.42, green: 0.16, blue: 0.08, alpha: 1.0)
        roofEaves.lineWidth = 2.0
        cottageWallNode.addChild(roofEaves)
        
        // Green ivy creeping at the corner
        for vi in 0...6 {
            let vy = CGFloat(vi) * 34 - 120
            let vx = wallW/2 - 6 + CGFloat.random(in: -6...6)
            let ivyCluster = SKShapeNode(circleOfRadius: CGFloat.random(in: 7...12))
            ivyCluster.position = CGPoint(x: vx, y: vy)
            ivyCluster.fillColor = SKColor(red: 0.28, green: 0.52, blue: 0.22, alpha: 0.85)
            ivyCluster.strokeColor = SKColor(red: 0.16, green: 0.34, blue: 0.12, alpha: 0.8)
            ivyCluster.lineWidth = 1.0
            cottageWallNode.addChild(ivyCluster)
        }
    }
    
    private func buildGroundAndPavers() {
        groundNode.position = CGPoint(x: 0, y: -120)
        groundNode.zPosition = 2
        container.addChild(groundNode)
        
        let groundW: CGFloat = 2000
        let groundH: CGFloat = 500
        
        // 1. Solid yard ground layer (Earth / Soil strata)
        let groundRect = CGRect(x: -groundW/2, y: -groundH, width: groundW, height: groundH)
        let ground = SKShapeNode(rect: groundRect)
        ground.fillColor = SKColor(red: 0.20, green: 0.14, blue: 0.09, alpha: 1.0)
        ground.strokeColor = SKColor(red: 0.10, green: 0.07, blue: 0.04, alpha: 1.0)
        ground.lineWidth = 2.0
        groundNode.addChild(ground)
        
        // Darker subsoil layer
        let subsoil = SKShapeNode(rect: CGRect(x: -groundW/2, y: -groundH, width: groundW, height: groundH - 35))
        subsoil.fillColor = SKColor(red: 0.14, green: 0.09, blue: 0.06, alpha: 1.0)
        subsoil.strokeColor = .clear
        groundNode.addChild(subsoil)
        
        // Pebbles & river stones embedded in the soil
        for px in [-220, -150, -40, 30, 160, 240] {
            let pebble = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 8...14), height: CGFloat.random(in: 5...8)))
            pebble.position = CGPoint(x: CGFloat(px), y: CGFloat.random(in: -80 ... -25))
            pebble.fillColor = SKColor(red: 0.35, green: 0.30, blue: 0.26, alpha: 0.8)
            pebble.strokeColor = .clear
            groundNode.addChild(pebble)
        }
        
        // 2. Straight horizontal lush grass turf line
        let grassLine = SKShapeNode()
        let gPath = CGMutablePath()
        gPath.move(to: CGPoint(x: -groundW/2, y: 0))
        gPath.addLine(to: CGPoint(x: groundW/2, y: 0))
        grassLine.path = gPath
        grassLine.strokeColor = SKColor(red: 0.30, green: 0.56, blue: 0.22, alpha: 1.0)
        grassLine.lineWidth = 6.0
        groundNode.addChild(grassLine)
        
        // Grass & wildflowers in the yard
        for i in -25...25 {
            let rx = CGFloat(i) * 18 + CGFloat.random(in: -4...4)
            // Skip stone and mud pit areas to keep them clear
            if (rx > -110 && rx < -60) || (rx > 68 && rx < 112) { continue }
            
            let blade = SKShapeNode()
            let bp = CGMutablePath()
            bp.move(to: CGPoint(x: rx, y: 0))
            bp.addLine(to: CGPoint(x: rx - 3, y: CGFloat.random(in: 6...11)))
            bp.move(to: CGPoint(x: rx + 2, y: 0))
            bp.addLine(to: CGPoint(x: rx + 4, y: CGFloat.random(in: 7...13)))
            blade.path = bp
            blade.strokeColor = SKColor(red: 0.36, green: 0.64, blue: 0.26, alpha: 0.9)
            blade.lineWidth = 1.5
            groundNode.addChild(blade)
            
            if i % 5 == 0 {
                let flower = SKShapeNode(circleOfRadius: 2.2)
                flower.position = CGPoint(x: rx, y: 9)
                flower.fillColor = i % 2 == 0 ? SKColor(red: 0.98, green: 0.88, blue: 0.40, alpha: 0.95) : SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
                flower.strokeColor = .clear
                groundNode.addChild(flower)
            }
        }
        
        // 3. LEFT LEG STONE FLAGSTONE PAVER (embedded straight into the ground)
        let paverW: CGFloat = 46
        let paverH: CGFloat = 14
        let paverRect = CGRect(x: -85 - (paverW / 2), y: -paverH + 2, width: paverW, height: paverH)
        stonePaverNode.path = CGPath(roundedRect: paverRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        stonePaverNode.fillColor = SKColor(red: 0.48, green: 0.45, blue: 0.42, alpha: 1.0)
        stonePaverNode.strokeColor = SKColor(red: 0.24, green: 0.22, blue: 0.20, alpha: 1.0)
        stonePaverNode.lineWidth = 2.0
        groundNode.addChild(stonePaverNode)
        
        let stoneBevel = SKShapeNode(rectOf: CGSize(width: paverW - 6, height: 2), cornerRadius: 1)
        stoneBevel.position = CGPoint(x: -85, y: 1)
        stoneBevel.fillColor = SKColor(red: 0.65, green: 0.62, blue: 0.58, alpha: 0.8)
        stoneBevel.strokeColor = .clear
        groundNode.addChild(stoneBevel)
        
        // 4. RIGHT LEG SUNKEN MUD PIT (embedded into the ground)
        let pitW: CGFloat = 62
        let pitH: CGFloat = 26
        let pitRect = CGRect(x: 90 - (pitW / 2), y: -pitH, width: pitW, height: pitH)
        sunkenPitNode.path = CGPath(ellipseIn: pitRect, transform: nil)
        sunkenPitNode.fillColor = SKColor(red: 0.12, green: 0.08, blue: 0.05, alpha: 0.98)
        sunkenPitNode.strokeColor = SKColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 0.9)
        sunkenPitNode.lineWidth = 2.0
        groundNode.addChild(sunkenPitNode)
        
        // Deep wet mud layer
        let wetMud = SKShapeNode(ellipseOf: CGSize(width: pitW - 12, height: pitH - 10))
        wetMud.position = CGPoint(x: 90, y: -pitH/2)
        wetMud.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.03, alpha: 1.0)
        wetMud.strokeColor = .clear
        groundNode.addChild(wetMud)
        
        // 5. FOREGROUND GROUND OVERLAY (Covers the base of the legs to make them look planted straight)
        buildForegroundGround()
    }
    
    private func buildForegroundGround() {
        groundForegroundNode.position = CGPoint(x: 0, y: -120)
        groundForegroundNode.zPosition = 6
        container.addChild(groundForegroundNode)
        
        // Foreground grass & soil around the left stone paver
        for gx in [-106, -100, -94, -76, -70, -64] {
            let grass = SKShapeNode()
            let gp = CGMutablePath()
            gp.move(to: CGPoint(x: CGFloat(gx), y: -3))
            gp.addLine(to: CGPoint(x: CGFloat(gx) - 2, y: CGFloat.random(in: 4...8)))
            gp.move(to: CGPoint(x: CGFloat(gx) + 2, y: -3))
            gp.addLine(to: CGPoint(x: CGFloat(gx) + 3, y: CGFloat.random(in: 5...9)))
            grass.path = gp
            grass.strokeColor = SKColor(red: 0.32, green: 0.60, blue: 0.24, alpha: 0.95)
            grass.lineWidth = 1.5
            groundForegroundNode.addChild(grass)
        }
        
        // Foreground mud lip around the right sinking pit
        let mudLipPath = CGMutablePath()
        mudLipPath.move(to: CGPoint(x: 62, y: 0))
        mudLipPath.addQuadCurve(to: CGPoint(x: 118, y: 0), control: CGPoint(x: 90, y: -6))
        mudLipPath.addQuadCurve(to: CGPoint(x: 62, y: 0), control: CGPoint(x: 90, y: 2))
        mudLipPath.closeSubpath()
        let mudLip = SKShapeNode(path: mudLipPath)
        mudLip.fillColor = SKColor(red: 0.18, green: 0.11, blue: 0.07, alpha: 0.95)
        mudLip.strokeColor = SKColor(red: 0.28, green: 0.16, blue: 0.10, alpha: 0.9)
        mudLip.lineWidth = 1.0
        groundForegroundNode.addChild(mudLip)
    }
    
    private func buildArtisanShelf() {
        // Left leg pivot planted straight on the stone paver (Grounded: y = -120)
        shelfPivotNode.position = CGPoint(x: -85, y: -120)
        shelfPivotNode.zPosition = 4
        container.addChild(shelfPivotNode)
        
        shelfPivotNode.addChild(shelfBodyNode)
        
        let legW: CGFloat = 18
        let legH: CGFloat = 108
        let span: CGFloat = 175 // Distance between left and right legs (from x: -85 to x: 90)
        
        // 1. LEFT LEG (Planted straight into the ground on the stone paver)
        let leftLegRect = CGRect(x: -legW/2, y: 0, width: legW, height: legH)
        leftLegNode.path = CGPath(roundedRect: leftLegRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        leftLegNode.fillColor = SKColor(red: 0.38, green: 0.24, blue: 0.14, alpha: 1.0)
        leftLegNode.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.07, alpha: 1.0)
        leftLegNode.lineWidth = 2.0
        shelfBodyNode.addChild(leftLegNode)
        
        // Left leg wood grain texture
        let leftGrain = SKShapeNode(rectOf: CGSize(width: 3, height: legH - 12), cornerRadius: 1)
        leftGrain.position = CGPoint(x: -2, y: legH/2)
        leftGrain.fillColor = SKColor(red: 0.48, green: 0.32, blue: 0.18, alpha: 0.7)
        leftGrain.strokeColor = .clear
        shelfBodyNode.addChild(leftGrain)
        
        // 2. RIGHT LEG (Planted straight into the mud pit)
        let rightLegRect = CGRect(x: span - legW/2, y: 0, width: legW, height: legH)
        rightLegNode.path = CGPath(roundedRect: rightLegRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        rightLegNode.fillColor = SKColor(red: 0.38, green: 0.24, blue: 0.14, alpha: 1.0)
        rightLegNode.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.07, alpha: 1.0)
        rightLegNode.lineWidth = 2.0
        shelfBodyNode.addChild(rightLegNode)
        
        // Right leg wood grain texture
        let rightGrain = SKShapeNode(rectOf: CGSize(width: 3, height: legH - 12), cornerRadius: 1)
        rightGrain.position = CGPoint(x: span - 2, y: legH/2)
        rightGrain.fillColor = SKColor(red: 0.48, green: 0.32, blue: 0.18, alpha: 0.7)
        rightGrain.strokeColor = .clear
        shelfBodyNode.addChild(rightGrain)
        
        // Middle wooden reinforcing crossbar (Timber Crossbar)
        let braceRect = CGRect(x: -legW/2, y: legH * 0.35, width: span + legW, height: 12)
        let brace = SKShapeNode(rect: braceRect, cornerRadius: 2)
        brace.fillColor = SKColor(red: 0.34, green: 0.21, blue: 0.12, alpha: 1.0)
        brace.strokeColor = SKColor(red: 0.18, green: 0.10, blue: 0.05, alpha: 1.0)
        brace.lineWidth = 1.5
        shelfBodyNode.addChild(brace)
        
        // Wooden dowel pins connecting the crossbar
        for bx in [0.0, span] {
            let bolt = SKShapeNode(circleOfRadius: 2.5)
            bolt.position = CGPoint(x: bx, y: legH * 0.35 + 6.0)
            bolt.fillColor = SKColor(red: 0.78, green: 0.62, blue: 0.32, alpha: 0.95)
            bolt.strokeColor = SKColor(red: 0.40, green: 0.26, blue: 0.12, alpha: 1.0)
            bolt.lineWidth = 0.8
            shelfBodyNode.addChild(bolt)
        }
        
        // Corner wooden braces
        let leftKneePath = CGMutablePath()
        leftKneePath.move(to: CGPoint(x: 0, y: legH - 18))
        leftKneePath.addLine(to: CGPoint(x: 20, y: legH))
        leftKneePath.addLine(to: CGPoint(x: 0, y: legH))
        leftKneePath.closeSubpath()
        let leftKnee = SKShapeNode(path: leftKneePath)
        leftKnee.fillColor = SKColor(red: 0.32, green: 0.20, blue: 0.11, alpha: 1.0)
        leftKnee.strokeColor = .clear
        shelfBodyNode.addChild(leftKnee)
        
        let rightKneePath = CGMutablePath()
        rightKneePath.move(to: CGPoint(x: span, y: legH - 18))
        rightKneePath.addLine(to: CGPoint(x: span - 20, y: legH))
        rightKneePath.addLine(to: CGPoint(x: span, y: legH))
        rightKneePath.closeSubpath()
        let rightKnee = SKShapeNode(path: rightKneePath)
        rightKnee.fillColor = SKColor(red: 0.32, green: 0.20, blue: 0.11, alpha: 1.0)
        rightKnee.strokeColor = .clear
        shelfBodyNode.addChild(rightKnee)
        
        // 3. TOP SHELF PLANK (Heavy Solid Timber Tabletop Plank)
        let plankOverhang: CGFloat = 25
        let plankW = span + (plankOverhang * 2)
        let plankH: CGFloat = 18
        let plankRect = CGRect(x: -plankOverhang, y: legH, width: plankW, height: plankH)
        shelfPlankNode.path = CGPath(roundedRect: plankRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        shelfPlankNode.fillColor = SKColor(red: 0.50, green: 0.32, blue: 0.18, alpha: 1.0)
        shelfPlankNode.strokeColor = SKColor(red: 0.26, green: 0.14, blue: 0.08, alpha: 1.0)
        shelfPlankNode.lineWidth = 2.5
        shelfBodyNode.addChild(shelfPlankNode)
        
        // Top edge wood highlight
        let plankTopHighlight = SKShapeNode(rectOf: CGSize(width: plankW - 8, height: 2.5), cornerRadius: 1)
        plankTopHighlight.position = CGPoint(x: span/2, y: legH + plankH - 2)
        plankTopHighlight.fillColor = SKColor(red: 0.65, green: 0.45, blue: 0.28, alpha: 0.7)
        plankTopHighlight.strokeColor = .clear
        shelfBodyNode.addChild(plankTopHighlight)
        
        // 4. MRS. MARA'S CLAY POTS (On top of the plank)
        // Pot 1: Terracotta jar on the left
        pot1Node.position = CGPoint(x: 20, y: legH + plankH)
        pot1Node.addChild(createClayPot(width: 44, height: 52, color: SKColor(red: 0.76, green: 0.44, blue: 0.26, alpha: 1.0)))
        shelfBodyNode.addChild(pot1Node)
        
        // Pot 2: Green celadon glazed bowl in the middle
        pot2Node.position = CGPoint(x: span * 0.5, y: legH + plankH)
        pot2Node.addChild(createGlazedPot(width: 38, height: 36, color: SKColor(red: 0.26, green: 0.60, blue: 0.48, alpha: 1.0)))
        shelfBodyNode.addChild(pot2Node)
        
        // Pot 3: Large earthenware on the right
        pot3Node.position = CGPoint(x: span - 20, y: legH + plankH)
        pot3Node.addChild(createClayPot(width: 52, height: 60, color: SKColor(red: 0.68, green: 0.38, blue: 0.20, alpha: 1.0)))
        shelfBodyNode.addChild(pot3Node)
        
        // 5. BRICK WEDGE & PIN (Wedging the right leg straight onto the ground)
        let brickW: CGFloat = 42
        let brickH: CGFloat = 20
        brickWedgeNode.position = CGPoint(x: span, y: 0)
        let brickRect = CGRect(x: -brickW/2, y: -brickH, width: brickW, height: brickH)
        brickWedgeNode.path = CGPath(roundedRect: brickRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        brickWedgeNode.fillColor = SKColor(red: 0.82, green: 0.34, blue: 0.22, alpha: 1.0)
        brickWedgeNode.strokeColor = SKColor(red: 0.45, green: 0.16, blue: 0.10, alpha: 1.0)
        brickWedgeNode.lineWidth = 2.0
        brickWedgeNode.alpha = 0
        shelfBodyNode.addChild(brickWedgeNode)
        
        let brickMortar = SKShapeNode(rectOf: CGSize(width: brickW - 6, height: 1.5))
        brickMortar.position = CGPoint(x: 0, y: -brickH/2)
        brickMortar.fillColor = SKColor(red: 0.95, green: 0.88, blue: 0.80, alpha: 0.6)
        brickMortar.strokeColor = .clear
        brickWedgeNode.addChild(brickMortar)
        
        // Wooden locking pin beside the brick
        let pasak = SKShapeNode()
        let pp = CGMutablePath()
        pp.move(to: CGPoint(x: -brickW/2 + 8, y: -brickH))
        pp.addLine(to: CGPoint(x: -brickW/2 + 3, y: 0))
        pp.addLine(to: CGPoint(x: -brickW/2 + 4, y: 0))
        pp.closeSubpath()
        pasak.path = pp
        pasak.fillColor = SKColor(red: 0.58, green: 0.38, blue: 0.20, alpha: 1.0)
        pasak.strokeColor = SKColor(red: 0.30, green: 0.18, blue: 0.08, alpha: 1.0)
        pasak.lineWidth = 1.0
        brickWedgeNode.addChild(pasak)
    }
    
    private func createClayPot(width: CGFloat, height: CGFloat, color: SKColor) -> SKNode {
        let pot = SKNode()
        let shadow = SKShapeNode(ellipseOf: CGSize(width: width * 0.85, height: 7))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.35)
        shadow.strokeColor = .clear
        pot.addChild(shadow)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width * 0.25, y: 2))
        path.addQuadCurve(to: CGPoint(x: -width * 0.5, y: height * 0.45), control: CGPoint(x: -width * 0.55, y: height * 0.15))
        path.addQuadCurve(to: CGPoint(x: -width * 0.25, y: height * 0.85), control: CGPoint(x: -width * 0.45, y: height * 0.7))
        path.addLine(to: CGPoint(x: -width * 0.32, y: height))
        path.addLine(to: CGPoint(x: width * 0.32, y: height))
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.85))
        path.addQuadCurve(to: CGPoint(x: width * 0.5, y: height * 0.45), control: CGPoint(x: width * 0.45, y: height * 0.7))
        path.addQuadCurve(to: CGPoint(x: width * 0.25, y: 2), control: CGPoint(x: width * 0.55, y: height * 0.15))
        path.closeSubpath()
        
        let body = SKShapeNode(path: path)
        body.fillColor = color
        body.strokeColor = SKColor(red: 0.36, green: 0.18, blue: 0.08, alpha: 1.0)
        body.lineWidth = 1.8
        pot.addChild(body)
        
        let rim = SKShapeNode(ellipseOf: CGSize(width: width * 0.7, height: 8))
        rim.position = CGPoint(x: 0, y: height)
        rim.fillColor = SKColor(red: 0.52, green: 0.28, blue: 0.15, alpha: 1.0)
        rim.strokeColor = SKColor(red: 0.30, green: 0.14, blue: 0.06, alpha: 1.0)
        rim.lineWidth = 1.2
        pot.addChild(rim)
        
        return pot
    }
    
    private func createGlazedPot(width: CGFloat, height: CGFloat, color: SKColor) -> SKNode {
        let pot = SKNode()
        let shadow = SKShapeNode(ellipseOf: CGSize(width: width * 0.85, height: 6))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        pot.addChild(shadow)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width * 0.28, y: 2))
        path.addQuadCurve(to: CGPoint(x: -width * 0.45, y: height * 0.5), control: CGPoint(x: -width * 0.5, y: height * 0.2))
        path.addQuadCurve(to: CGPoint(x: -width * 0.28, y: height), control: CGPoint(x: -width * 0.4, y: height * 0.8))
        path.addLine(to: CGPoint(x: width * 0.28, y: height))
        path.addQuadCurve(to: CGPoint(x: width * 0.45, y: height * 0.5), control: CGPoint(x: width * 0.4, y: height * 0.8))
        path.addQuadCurve(to: CGPoint(x: width * 0.28, y: 2), control: CGPoint(x: width * 0.5, y: height * 0.2))
        path.closeSubpath()
        
        let body = SKShapeNode(path: path)
        body.fillColor = color
        body.strokeColor = SKColor(red: 0.12, green: 0.35, blue: 0.28, alpha: 1.0)
        body.lineWidth = 1.8
        pot.addChild(body)
        
        return pot
    }
    
    private func buildWaterpass() {
        waterpassNode.position = CGPoint(x: 0, y: 70)
        waterpassNode.zPosition = 6
        container.addChild(waterpassNode)
        
        // Elegant Brass Casing with bevel
        let casing = SKShapeNode(rectOf: CGSize(width: 130, height: 22), cornerRadius: 11)
        casing.fillColor = SKColor(red: 0.22, green: 0.17, blue: 0.10, alpha: 0.95)
        casing.strokeColor = SKColor(red: 0.78, green: 0.62, blue: 0.32, alpha: 1.0)
        casing.lineWidth = 1.8
        waterpassNode.addChild(casing)
        
        // Dark Glass Tube
        let tube = SKShapeNode(rectOf: CGSize(width: 106, height: 13), cornerRadius: 6.5)
        tube.fillColor = SKColor(red: 0.08, green: 0.10, blue: 0.08, alpha: 0.9)
        tube.strokeColor = SKColor(red: 0.35, green: 0.28, blue: 0.18, alpha: 0.6)
        tube.lineWidth = 1.0
        waterpassNode.addChild(tube)
        
        // Center Balance Zone (Target)
        let centerLine = SKShapeNode(rectOf: CGSize(width: 22, height: 13), cornerRadius: 3)
        centerLine.fillColor = SKColor(red: 0.25, green: 0.85, blue: 0.45, alpha: 0.18)
        centerLine.strokeColor = SKColor(red: 0.85, green: 0.75, blue: 0.45, alpha: 0.5)
        centerLine.lineWidth = 1.0
        waterpassNode.addChild(centerLine)
        
        // Green glow when balanced
        waterpassGlow.path = CGPath(roundedRect: CGRect(x: -60, y: -10, width: 120, height: 20), cornerWidth: 10, cornerHeight: 10, transform: nil)
        waterpassGlow.fillColor = SKColor(red: 0.25, green: 0.95, blue: 0.45, alpha: 0.25)
        waterpassGlow.strokeColor = .clear
        waterpassGlow.blendMode = .add
        waterpassGlow.alpha = 0.0
        waterpassNode.addChild(waterpassGlow)
        
        // Spirit Liquid Bubble
        waterpassBubble.path = CGPath(ellipseIn: CGRect(x: -7, y: -5.5, width: 14, height: 11), transform: nil)
        waterpassBubble.fillColor = SKColor(red: 0.95, green: 0.75, blue: 0.35, alpha: 0.95)
        waterpassBubble.strokeColor = SKColor.white
        waterpassBubble.lineWidth = 1.0
        waterpassNode.addChild(waterpassBubble)
    }
    
    private func buildDBDTrack() {
        // Track placed exactly at the gap under the right leg where the brick will be wedged
        dbdTrackNode.position = CGPoint(x: 0, y: -205)
        dbdTrackNode.zPosition = 8
        container.addChild(dbdTrackNode)
        
        // Carved wooden base
        let trackBg = SKShapeNode(rectOf: CGSize(width: dbdTrackWidth + 14, height: 26), cornerRadius: 13)
        trackBg.fillColor = SKColor(red: 0.14, green: 0.10, blue: 0.07, alpha: 0.96)
        trackBg.strokeColor = SKColor(red: 0.52, green: 0.38, blue: 0.22, alpha: 1.0)
        trackBg.lineWidth = 2.0
        dbdTrackNode.addChild(trackBg)
        
        // Inner slider track
        let trackInner = SKShapeNode(rectOf: CGSize(width: dbdTrackWidth, height: 12), cornerRadius: 6)
        trackInner.fillColor = SKColor(red: 0.08, green: 0.06, blue: 0.04, alpha: 1.0)
        trackInner.strokeColor = SKColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 0.7)
        trackInner.lineWidth = 1.0
        dbdTrackNode.addChild(trackInner)
        
        // Brass rivets at the left and right ends
        for xOffset in [-(dbdTrackWidth/2 + 2), (dbdTrackWidth/2 + 2)] {
            let rivet = SKShapeNode(circleOfRadius: 2.5)
            rivet.fillColor = SKColor(red: 0.85, green: 0.70, blue: 0.35, alpha: 0.9)
            rivet.strokeColor = SKColor(red: 0.4, green: 0.3, blue: 0.15, alpha: 1.0)
            rivet.lineWidth = 0.8
            rivet.position = CGPoint(x: xOffset, y: 0)
            dbdTrackNode.addChild(rivet)
        }
        
        // Green Zone (Precision Target Area with soft glow)
        let zoneW = dbdTrackWidth * (config.dbdTargetEnd - config.dbdTargetStart)
        let zoneX = (-dbdTrackWidth / 2) + (dbdTrackWidth * config.dbdTargetStart) + (zoneW / 2)
        
        dbdTargetZoneNode.path = CGPath(roundedRect: CGRect(x: -zoneW/2, y: -7, width: zoneW, height: 14), cornerWidth: 4, cornerHeight: 4, transform: nil)
        dbdTargetZoneNode.fillColor = SKColor(red: 0.20, green: 0.82, blue: 0.40, alpha: 0.85)
        dbdTargetZoneNode.strokeColor = SKColor(red: 0.60, green: 1.0, blue: 0.70, alpha: 1.0)
        dbdTargetZoneNode.lineWidth = 1.5
        dbdTargetZoneNode.position = CGPoint(x: zoneX, y: 0)
        dbdTrackNode.addChild(dbdTargetZoneNode)
        
        // Red Brick Cursor (Artisan Terracotta Brick)
        let cursorPath = CGMutablePath()
        cursorPath.addRoundedRect(in: CGRect(x: -12, y: -13, width: 24, height: 26), cornerWidth: 3, cornerHeight: 3)
        dbdCursorNode.path = cursorPath
        dbdCursorNode.fillColor = SKColor(red: 0.82, green: 0.32, blue: 0.20, alpha: 1.0)
        dbdCursorNode.strokeColor = SKColor(red: 0.98, green: 0.88, blue: 0.75, alpha: 1.0)
        dbdCursorNode.lineWidth = 1.8
        dbdCursorNode.position = CGPoint(x: -dbdTrackWidth/2, y: 0)
        dbdTrackNode.addChild(dbdCursorNode)
        
        let mortar = SKShapeNode(rectOf: CGSize(width: 20, height: 1.5))
        mortar.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.75, alpha: 0.5)
        mortar.strokeColor = .clear
        dbdCursorNode.addChild(mortar)
        
        dbdTrackNode.alpha = 0.0 // Hidden until the shelf is lifted and balanced
    }
    
    private func buildMinimalHUD() {
        // Ultra-minimalist HUD: No long text, just a small badge & dismiss button
        headerBar.position = CGPoint(x: 0, y: 330)
        headerBar.zPosition = 10
        container.addChild(headerBar)
        
        let pillBg = SKShapeNode(rectOf: CGSize(width: 120, height: 26), cornerRadius: 13)
        pillBg.fillColor = SKColor(red: 0.14, green: 0.10, blue: 0.07, alpha: 0.92)
        pillBg.strokeColor = SKColor(red: 0.70, green: 0.54, blue: 0.30, alpha: 0.8)
        pillBg.lineWidth = 1.5
        headerBar.addChild(pillBg)
        
        headerTitleLabel.text = "WEDGE SHELF"
        headerTitleLabel.fontName = "AvenirNext-Bold"
        headerTitleLabel.fontSize = 11
        headerTitleLabel.fontColor = SKColor(red: 0.95, green: 0.88, blue: 0.72, alpha: 1.0)
        headerTitleLabel.verticalAlignmentMode = .center
        headerTitleLabel.position = CGPoint(x: 0, y: 0)
        headerBar.addChild(headerTitleLabel)
        
        // Artistic Close/Dismiss Button (Wood & Gold)
        let dismissBtn = SKShapeNode(circleOfRadius: 16)
        dismissBtn.fillColor = SKColor(red: 0.16, green: 0.12, blue: 0.08, alpha: 0.9)
        dismissBtn.strokeColor = SKColor(red: 0.65, green: 0.50, blue: 0.30, alpha: 0.8)
        dismissBtn.lineWidth = 1.5
        dismissBtn.position = CGPoint(x: 155, y: 0)
        dismissBtn.name = "dismissBtn"
        
        let xLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        xLabel.text = "✕"
        xLabel.fontSize = 12
        xLabel.fontColor = SKColor(red: 0.95, green: 0.88, blue: 0.72, alpha: 0.9)
        xLabel.verticalAlignmentMode = .center
        xLabel.horizontalAlignmentMode = .center
        dismissBtn.addChild(xLabel)
        headerBar.addChild(dismissBtn)
        
        // Hammer Tap Indicator (Visual Pips, no text!)
        buildHammerIndicator()
    }
    
    private func buildHammerIndicator() {
        hammerPromptNode.position = CGPoint(x: 82, y: -70)
        hammerPromptNode.zPosition = 9
        hammerPromptNode.alpha = 0.0
        container.addChild(hammerPromptNode)
        
        let promptBg = SKShapeNode(rectOf: CGSize(width: 52, height: 24), cornerRadius: 12)
        promptBg.fillColor = SKColor(red: 0.12, green: 0.09, blue: 0.06, alpha: 0.95)
        promptBg.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.32, alpha: 1.0)
        promptBg.lineWidth = 1.5
        hammerPromptNode.addChild(promptBg)
        
        // Pip 1
        hammerPip1.path = CGPath(ellipseIn: CGRect(x: -14, y: -4, width: 8, height: 8), transform: nil)
        hammerPip1.fillColor = SKColor.white.withAlphaComponent(0.25)
        hammerPip1.strokeColor = SKColor.white.withAlphaComponent(0.7)
        hammerPip1.lineWidth = 1.0
        hammerPromptNode.addChild(hammerPip1)
        
        // Pip 2
        hammerPip2.path = CGPath(ellipseIn: CGRect(x: 6, y: -4, width: 8, height: 8), transform: nil)
        hammerPip2.fillColor = SKColor.white.withAlphaComponent(0.25)
        hammerPip2.strokeColor = SKColor.white.withAlphaComponent(0.7)
        hammerPip2.lineWidth = 1.0
        hammerPromptNode.addChild(hammerPip2)
    }
    
    // MARK: - CoreMotion & Update Loop
    
    public func start() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true
        lastUpdateTime = 0
        
        container.setScale(0.88)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.3),
            .scale(to: 1.0, duration: 0.35).applyTimingMode(.easeOut)
        ]))
        
        #if canImport(UIKit)
        HapticsService.shared.playSelection()
        #endif
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates()
        }
        
        // Mrs. Mara's opening dialogue with SpeechBubbleNode
        showBuMaraDialog("Arthur! Help me, my pottery shelf is tilting and the pots are about to fall!")
        
        let loop = SKAction.customAction(withDuration: 1000.0) { [weak self] _, elapsedTime in
            guard let self, self.isRunning else { return }
            let dt = self.lastUpdateTime == 0 ? 1.0/60.0 : min(0.05, Double(elapsedTime) - self.lastUpdateTime)
            self.lastUpdateTime = Double(elapsedTime)
            
            self.updatePhysics(deltaTime: dt)
        }
        run(loop, withKey: "shelfLoop")
    }
    
    private func updatePhysics(deltaTime: TimeInterval) {
        if isWedgePlaced {
            // Shelf is wedged: Stands firm, straight, and doesn't lift!
            shelfAngle = 0.0
            shelfPivotNode.zRotation = 0.0
            waterpassBubble.position.x = 0.0
            return
        }
        
        // CoreMotion: Read device tilt in portrait mode
        var tilt: CGFloat = simulatedTilt
        if let motion = motionManager.deviceMotion {
            tilt = CGFloat(motion.gravity.x)
        }
        
        if isShelfLifted {
            // ONCE SHELF IS LIFTED: STAYS in lifted position, balanced via Gyro
            let targetTilt = -tilt * 0.35
            shelfAngle += (targetTilt - shelfAngle) * CGFloat(deltaTime * 6.0)
            
            // Cap rotation so it doesn't float above ground
            shelfAngle = max(-0.09, min(0.18, shelfAngle))
            
            // Check balance status
            let prevBalanced = isBalanced
            isBalanced = abs(shelfAngle) <= config.balanceTolerance
            
            if isBalanced && !prevBalanced {
                dbdTrackNode.run(.fadeAlpha(to: 1.0, duration: 0.2))
                waterpassBubble.fillColor = SKColor(red: 0.25, green: 0.95, blue: 0.45, alpha: 1.0)
                waterpassGlow.run(.fadeAlpha(to: 0.7, duration: 0.2))
                #if canImport(UIKit)
                HapticsService.shared.playImpact(style: .light)
                #endif
            } else if !isBalanced && prevBalanced {
                dbdTrackNode.run(.fadeAlpha(to: 0.35, duration: 0.2))
                waterpassBubble.fillColor = SKColor(red: 0.95, green: 0.75, blue: 0.35, alpha: 1.0)
                waterpassGlow.run(.fadeAlpha(to: 0.0, duration: 0.2))
            }
            
            // Move DBD slider only when balanced
            if isBalanced && !isWedgePlaced {
                sliderProgress += (config.dbdSliderSpeed * CGFloat(deltaTime)) * sliderDirection
                if sliderProgress >= 1.0 { sliderProgress = 1.0; sliderDirection = -1.0 }
                if sliderProgress <= 0.0 { sliderProgress = 0.0; sliderDirection = 1.0 }
                
                let cursorX = (-dbdTrackWidth / 2) + (sliderProgress * dbdTrackWidth)
                dbdCursorNode.position.x = cursorX
            }
            
        } else {
            // BEFORE LIFTED: Gyro tilt / drag lifts the shelf from the mud to a straight position
            let targetTilt = 0.17 + (tilt * 0.35)
            shelfAngle += (targetTilt - shelfAngle) * CGFloat(deltaTime * 5.0)
            
            // Once lifted near 0 degrees, it IMMEDIATELY STAYS up!
            if abs(shelfAngle) <= config.balanceTolerance {
                isShelfLifted = true
                shelfAngle = 0.0
                #if canImport(UIKit)
                HapticsService.shared.playImpact(style: .medium)
                #endif
            }
        }
        
        // Apply shelf rotation pivoting on the left leg
        shelfPivotNode.zRotation = -shelfAngle
        
        // Update waterpass bubble position
        let bubbleX = max(-45, min(45, -shelfAngle * 180))
        waterpassBubble.position.x = bubbleX
        
        // Check if tilt exceeds limit (Pots Slip & Break)
        if abs(shelfAngle) > config.failAngle {
            handleFailTippedOver()
        }
    }
    
    // MARK: - Touch Handling (Precision Tap & Drag Fallback)
    
    #if canImport(UIKit)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning else { return }
        
        // Check dismiss button
        if let touch = touches.first {
            let locInHeader = touch.location(in: headerBar)
            if hypot(locInHeader.x - 155, locInHeader.y) <= 24 {
                cancel()
                onDismiss?()
                return
            }
        }
        
        if isShelfLifted && !isWedgePlaced {
            // Precision Tap DBD Slider
            evaluateDBDTap()
        } else if !isShelfLifted {
            // Tap to immediately lift shelf and STAY straight
            isShelfLifted = true
            shelfAngle = 0.0
            shelfPivotNode.zRotation = 0.0
            #if canImport(UIKit)
            HapticsService.shared.playImpact(style: .medium)
            #endif
        } else if isWedgePlaced && hammerTaps < 2 {
            // Hammer tap to lock the pin
            handleHammerTap()
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning && !isWedgePlaced, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        simulatedTilt = (loc.x / 140.0)
    }
    #endif
    
    // MARK: - QTE Evaluation & Success/Fail
    
    private func evaluateDBDTap() {
        if isBalanced && sliderProgress >= config.dbdTargetStart && sliderProgress <= config.dbdTargetEnd {
            // SUCCESS! Brick slides perfectly under the right leg
            handleSuccessWedge()
        } else {
            // MISSED! Leg sinks back into the mud
            handleMissedTap()
        }
    }
    
    private func handleSuccessWedge() {
        isWedgePlaced = true
        shelfAngle = 0.0
        shelfPivotNode.zRotation = 0.0
        motionManager.stopDeviceMotionUpdates()
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.success)
        #endif
        
        dbdTrackNode.run(.fadeOut(withDuration: 0.15))
        
        // Brick appears wedging the right leg flat on the ground so it stays straight
        brickWedgeNode.alpha = 1.0
        brickWedgeNode.setScale(0.2)
        brickWedgeNode.run(.scale(to: 1.0, duration: 0.15).applyTimingMode(.easeOut))
        
        // Waterpass instantly perfectly balanced
        waterpassBubble.position.x = 0.0
        waterpassBubble.fillColor = SKColor(red: 0.25, green: 0.95, blue: 0.45, alpha: 1.0)
        waterpassGlow.run(.fadeAlpha(to: 0.8, duration: 0.15))
        
        // Visual hammer tap indicator appears
        hammerPromptNode.run(.fadeIn(withDuration: 0.2))
        
        showBuMaraDialog("Lock the brick in now!", isSuccess: true)
    }
    
    private func handleHammerTap() {
        hammerTaps += 1
        
        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: hammerTaps == 2 ? .heavy : .medium)
        #endif
        
        // Solid hammer hit effect locking the pin into the ground (doesn't float)
        shelfPivotNode.run(.sequence([
            .moveBy(x: 0, y: -2.5, duration: 0.03),
            .moveBy(x: 0, y: 2.5, duration: 0.03)
        ]))
        
        // Update visual pip indicator
        if hammerTaps == 1 {
            hammerPip1.fillColor = SKColor(red: 0.95, green: 0.82, blue: 0.35, alpha: 1.0)
            hammerPromptNode.run(.sequence([
                .scale(to: 1.25, duration: 0.08),
                .scale(to: 1.0, duration: 0.08)
            ]))
        } else if hammerTaps >= 2 {
            hammerPip2.fillColor = SKColor(red: 0.95, green: 0.82, blue: 0.35, alpha: 1.0)
            hammerPromptNode.run(.sequence([
                .scale(to: 1.25, duration: 0.08),
                .scale(to: 1.0, duration: 0.08)
            ]))
            finishGameSuccess()
        }
    }
    
    private func finishGameSuccess() {
        isRunning = false
        isCompleted = true
        removeAction(forKey: "shelfLoop")
        motionManager.stopDeviceMotionUpdates()
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.success)
        #endif
        
        hammerPromptNode.run(.fadeOut(withDuration: 0.2))
        
        // Glowing victory effect
        let winGlow = SKShapeNode(rectOf: CGSize(width: 280, height: 140), cornerRadius: 8)
        winGlow.position = CGPoint(x: 85, y: 55)
        winGlow.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 0.35)
        winGlow.strokeColor = .clear
        winGlow.blendMode = .add
        winGlow.zPosition = 6
        shelfBodyNode.addChild(winGlow)
        winGlow.run(.sequence([
            .scale(to: 1.15, duration: 0.35).applyTimingMode(.easeOut),
            .fadeOut(withDuration: 0.4),
            .removeFromParent()
        ]))
        
        showBuMaraDialog("The shelf is sturdy now! Thank you!", isSuccess: true)
        
        onComplete?(true)
        
        run(.sequence([
            .wait(forDuration: 2.8),
            .run { [weak self] in
                self?.onDismiss?()
                self?.removeFromParent()
            }
        ]))
    }
    
    private func handleMissedTap() {
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.error)
        #endif
        
        // Leg sinks back into the mud
        isShelfLifted = false
        shelfAngle = 0.17
        shelfPivotNode.zRotation = -shelfAngle
        
        dbdTrackNode.run(.fadeAlpha(to: 0.0, duration: 0.15))
        
        // Hard impact shake
        container.run(.sequence([
            .moveBy(x: -8, y: 0, duration: 0.04),
            .moveBy(x: 16, y: 0, duration: 0.08),
            .moveBy(x: -8, y: 0, duration: 0.04)
        ]))
        
        showBuMaraDialog("Oh no, the brick missed!")
    }
    
    private func handleFailTippedOver() {
        guard isRunning else { return }
        isRunning = false
        isCompleted = true
        removeAction(forKey: "shelfLoop")
        motionManager.stopDeviceMotionUpdates()
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.error)
        #endif
        
        // Pots fall and break
        pot1Node.run(.moveBy(x: -60, y: -90, duration: 0.3).applyTimingMode(.easeIn))
        pot2Node.run(.moveBy(x: 40, y: -100, duration: 0.3).applyTimingMode(.easeIn))
        pot3Node.run(.moveBy(x: 80, y: -110, duration: 0.3).applyTimingMode(.easeIn))
        
        showBuMaraDialog("Oh my, the pots broke!")
        
        onComplete?(false)
        
        run(.sequence([
            .wait(forDuration: 2.8),
            .run { [weak self] in
                self?.onDismiss?()
                self?.removeFromParent()
            }
        ]))
    }
    
    // MARK: - SpeechBubble Dialog System
    
    private func showBuMaraDialog(_ message: String, isSuccess: Bool = false) {
        activeSpeechBubble?.popOut()
        activeSpeechBubble = nil
        
        let config = SpeechBubbleConfig(
            text: message,
            speaker: "MRS. MARA",
            fontName: "AvenirNext-Bold",
            fontSize: 13,
            fontColor: .white,
            speakerColor: isSuccess ? SKColor(red: 0.45, green: 0.90, blue: 0.55, alpha: 1.0) : SKColor(red: 0.96, green: 0.83, blue: 0.48, alpha: 1.0),
            backgroundColor: SKColor(red: 0.08, green: 0.07, blue: 0.09, alpha: 0.96),
            crayonStrokeColor: isSuccess ? SKColor(red: 0.25, green: 0.70, blue: 0.35, alpha: 0.9) : SKColor(red: 0.85, green: 0.50, blue: 0.30, alpha: 0.9),
            padding: CGSize(width: 20, height: 12),
            maxWidth: 280,
            cornerRadius: 15
        )
        
        let bubble = SpeechBubbleNode(config: config, tailTipOffset: CGPoint(x: -60, y: -40))
        bubble.position = CGPoint(x: 0, y: -310)
        bubble.zPosition = 100
        container.addChild(bubble)
        bubble.popIn()
        activeSpeechBubble = bubble
        
        bubble.run(.sequence([
            .wait(forDuration: 2.2),
            .run { [weak self, weak bubble] in
                if self?.activeSpeechBubble == bubble {
                    self?.activeSpeechBubble = nil
                }
                bubble?.popOut()
            }
        ]))
    }
    
    public func cancel() {
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
        removeAllActions()
        removeFromParent()
    }
}

// MARK: - SwiftUI View Wrapper (Consistent API & Previews)

#if canImport(SwiftUI)
import SwiftUI

public struct BuMaraShelfMinigameView: View {
    public var onComplete: ((Bool) -> Void)?
    public var onDismiss: (() -> Void)?
    
    public init(onComplete: ((Bool) -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        SpriteView(scene: {
            let scene = SKScene(size: CGSize(width: 393, height: 852)) // Portrait size
            scene.scaleMode = .resizeFill
            scene.backgroundColor = SKColor(red: 0.55, green: 0.74, blue: 0.86, alpha: 1.0)
            
            let minigame = ShelfBalanceMinigameNode()
            minigame.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
            minigame.onComplete = onComplete
            minigame.onDismiss = onDismiss
            scene.addChild(minigame)
            minigame.start()
            
            return scene
        }())
        .ignoresSafeArea()
    }
}

// Compatibility Aliases
public typealias ShelfBalanceMinigame = BuMaraShelfMinigameView
public typealias ShelfBalanceMinigameView = BuMaraShelfMinigameView

#if DEBUG
#Preview("Bu Mara Shelf Minigame (SpriteKit & SpeechBubble)") {
    BuMaraShelfMinigameView()
}
#endif
#endif
