import SpriteKit
import UIKit
import CoreImage

extension GameScene {
    func configureTransitionFog() {
        transitionFog.name = "TransitionFog"
        transitionFog.zPosition = 10_000
        transitionFog.alpha = 0
        transitionFog.isHidden = true
        transitionFog.shouldRasterize = true
        transitionFog.shouldEnableEffects = true
        transitionFog.filter = CIFilter(
            name: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: 54]
        )

        let veil = SKSpriteNode(
            color: SKColor(red: 0.84, green: 0.91, blue: 0.94, alpha: 0.88),
            size: CGSize(width: size.width * 2.8, height: size.height * 2.8)
        )
        veil.name = "TransitionFogVeil"
        veil.zPosition = 0
        transitionFog.addChild(veil)

        let cloudStartPositions: [CGPoint] = [
            CGPoint(x: -size.width * 0.88, y: size.height * 0.40),
            CGPoint(x: -size.width * 0.92, y: 0),
            CGPoint(x: -size.width * 0.86, y: -size.height * 0.42),
            CGPoint(x: size.width * 0.88, y: size.height * 0.40),
            CGPoint(x: size.width * 0.92, y: 0),
            CGPoint(x: size.width * 0.86, y: -size.height * 0.42),
            CGPoint(x: -size.width * 0.38, y: size.height * 0.86),
            CGPoint(x: size.width * 0.10, y: size.height * 0.90),
            CGPoint(x: size.width * 0.42, y: size.height * 0.84),
            CGPoint(x: -size.width * 0.40, y: -size.height * 0.86),
            CGPoint(x: size.width * 0.08, y: -size.height * 0.90),
            CGPoint(x: size.width * 0.44, y: -size.height * 0.84)
        ]

        for (index, position) in cloudStartPositions.enumerated() {
            let cloudRoot = SKNode()
            cloudRoot.name = "TransitionCloud_\(index)"
            cloudRoot.position = position
            cloudRoot.zPosition = 1

            let baseRadius = max(size.width, size.height) * 0.25
            let lobeOffsets: [CGPoint] = [
                CGPoint(x: -baseRadius * 0.55, y: 0),
                CGPoint(x: 0, y: baseRadius * 0.18),
                CGPoint(x: baseRadius * 0.52, y: -baseRadius * 0.04),
                CGPoint(x: -baseRadius * 0.10, y: -baseRadius * 0.30)
            ]

            for (lobeIndex, offset) in lobeOffsets.enumerated() {
                let radius = baseRadius * (lobeIndex == 1 ? 1.08 : 0.92)
                let lobe = SKShapeNode(circleOfRadius: radius)
                lobe.position = offset
                lobe.xScale = lobeIndex.isMultiple(of: 2) ? 1.20 : 0.96
                lobe.yScale = lobeIndex.isMultiple(of: 2) ? 0.82 : 1.04
                lobe.fillColor = SKColor.white.withAlphaComponent(0.58)
                lobe.strokeColor = .clear
                cloudRoot.addChild(lobe)
            }

            transitionFog.addChild(cloudRoot)
        }
    }

    func configureJoystick() {
        joystickBase.name = "MovementJoystickBase"
        joystickBase.fillColor = SKColor.black.withAlphaComponent(0.30)
        joystickBase.strokeColor = SKColor.white.withAlphaComponent(0.62)
        joystickBase.lineWidth = 4
        joystickBase.zPosition = 11_000
        joystickBase.alpha = 0
        joystickBase.isHidden = true
        joystickBase.addChild(joystickKnob)

        joystickKnob.name = "MovementJoystickKnob"
        joystickKnob.fillColor = SKColor.white.withAlphaComponent(0.82)
        joystickKnob.strokeColor = SKColor.white
        joystickKnob.lineWidth = 3
        joystickKnob.zPosition = 1
    }

    func showJoystick(at position: CGPoint) {
        joystickBase.removeAllActions()
        joystickBase.position = position
        joystickKnob.position = .zero
        joystickBase.isHidden = false
        joystickBase.run(.fadeAlpha(to: 1, duration: 0.08))
    }

    func updateJoystick(to position: CGPoint) {
        let dx = position.x - joystickBase.position.x
        let dy = position.y - joystickBase.position.y
        let distance = hypot(dx, dy)
        let maximumDistance: CGFloat = 72
        guard distance > maximumDistance else {
            joystickKnob.position = CGPoint(x: dx, y: dy)
            return
        }

        joystickKnob.position = CGPoint(
            x: dx / distance * maximumDistance,
            y: dy / distance * maximumDistance
        )
    }

    func hideJoystick() {
        joystickBase.removeAllActions()
        joystickBase.run(.sequence([
            .fadeOut(withDuration: 0.10),
            .run { [weak self] in
                self?.joystickBase.isHidden = true
                self?.joystickKnob.position = .zero
            }
        ]))
    }

    func playTransitionFog(onCovered: @escaping () -> Void) {
        transitionFog.removeAllActions()
        transitionFog.children.forEach { $0.removeAllActions() }
        transitionFog.isHidden = false
        transitionFog.alpha = 1
        transitionFog.setScale(1)

        let cloudStartPositions: [CGPoint] = [
            CGPoint(x: -size.width * 0.88, y: size.height * 0.40),
            CGPoint(x: -size.width * 0.92, y: 0),
            CGPoint(x: -size.width * 0.86, y: -size.height * 0.42),
            CGPoint(x: size.width * 0.88, y: size.height * 0.40),
            CGPoint(x: size.width * 0.92, y: 0),
            CGPoint(x: size.width * 0.86, y: -size.height * 0.42),
            CGPoint(x: -size.width * 0.38, y: size.height * 0.86),
            CGPoint(x: size.width * 0.10, y: size.height * 0.90),
            CGPoint(x: size.width * 0.42, y: size.height * 0.84),
            CGPoint(x: -size.width * 0.40, y: -size.height * 0.86),
            CGPoint(x: size.width * 0.08, y: -size.height * 0.90),
            CGPoint(x: size.width * 0.44, y: -size.height * 0.84)
        ]

        let cloudCenterPositions: [CGPoint] = [
            CGPoint(x: -size.width * 0.16, y: size.height * 0.18),
            CGPoint(x: -size.width * 0.18, y: 0),
            CGPoint(x: -size.width * 0.16, y: -size.height * 0.18),
            CGPoint(x: size.width * 0.16, y: size.height * 0.18),
            CGPoint(x: size.width * 0.18, y: 0),
            CGPoint(x: size.width * 0.16, y: -size.height * 0.18),
            CGPoint(x: -size.width * 0.10, y: size.height * 0.18),
            CGPoint(x: size.width * 0.02, y: size.height * 0.16),
            CGPoint(x: size.width * 0.12, y: size.height * 0.18),
            CGPoint(x: -size.width * 0.10, y: -size.height * 0.18),
            CGPoint(x: size.width * 0.02, y: -size.height * 0.16),
            CGPoint(x: size.width * 0.12, y: -size.height * 0.18)
        ]

        if let veil = transitionFog.childNode(withName: "TransitionFogVeil") {
            veil.alpha = 0
            let veilIn = SKAction.fadeAlpha(to: 1, duration: 0.48)
            veilIn.timingMode = .easeInEaseOut
            veil.run(veilIn)
        }

        for index in cloudStartPositions.indices {
            guard let cloud = transitionFog.childNode(withName: "TransitionCloud_\(index)") else {
                continue
            }

            cloud.position = cloudStartPositions[index]
            cloud.alpha = 0.28
            cloud.setScale(0.92)

            let moveIn = SKAction.move(
                to: cloudCenterPositions[index],
                duration: 0.58 + Double(index % 3) * 0.025
            )
            moveIn.timingMode = .easeInEaseOut

            let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.40)
            fadeIn.timingMode = .easeOut

            let grow = SKAction.scale(to: 1.08, duration: 0.60)
            grow.timingMode = .easeInEaseOut

            cloud.run(.group([moveIn, fadeIn, grow]))
        }

        transitionFog.run(.sequence([
            .wait(forDuration: 0.70),
            .run(onCovered),
            .wait(forDuration: 0.10),
            .run { [weak self] in
                guard let self else { return }

                if let veil = self.transitionFog.childNode(withName: "TransitionFogVeil") {
                    let veilOut = SKAction.fadeOut(withDuration: 0.58)
                    veilOut.timingMode = .easeInEaseOut
                    veil.run(veilOut)
                }

                for index in cloudStartPositions.indices {
                    guard let cloud = self.transitionFog.childNode(withName: "TransitionCloud_\(index)") else {
                        continue
                    }

                    let moveOut = SKAction.move(
                        to: cloudStartPositions[index],
                        duration: 0.58 + Double(index % 2) * 0.03
                    )
                    moveOut.timingMode = .easeInEaseOut

                    let fadeOut = SKAction.fadeOut(withDuration: 0.52)
                    fadeOut.timingMode = .easeInEaseOut

                    let shrink = SKAction.scale(to: 0.96, duration: 0.58)
                    shrink.timingMode = .easeInEaseOut

                    cloud.run(.group([moveOut, fadeOut, shrink]))
                }
            },
            .wait(forDuration: 0.64),
            .run { [weak self] in
                guard let self else { return }
                self.transitionFog.isHidden = true
                self.transitionFog.alpha = 0
            }
        ]))
    }

    func configurePuzzleFeedback() {
        puzzleFeedbackLabel.text = ""
        puzzleFeedbackLabel.fontSize = 42
        puzzleFeedbackLabel.fontColor = .systemYellow
        puzzleFeedbackLabel.verticalAlignmentMode = .center
        puzzleFeedbackLabel.horizontalAlignmentMode = .center
        puzzleFeedbackLabel.zPosition = 1_200
        puzzleFeedbackLabel.alpha = 0
    }

    func handlePuzzleCompleted(_ puzzleID: PuzzleID) {
        print("[Puzzle] \(puzzleID.rawValue) completed")
        worldEventManager.recordPuzzleStatus(.completed, for: puzzleID)
        queueOrPresent(.puzzleCompleted(puzzleID))
        let emittedEvents = worldEventManager.handle(.puzzleCompleted(puzzleID), worldState: &worldState)
        playerController.updateWorldState(worldState)
        worldRenderer.applyWorldState(worldState, in: worldRoot, showsDebugLabels: showsDebugOverlay)

        for event in emittedEvents {
            queueOrPresent(event)
        }
        autosave(reason: "puzzle completed")
    }

    func resolveLandmarkArrival(at playerPosition: CGPoint) {
        guard gameMode == .exploring,
              worldEventManager.progressState.prototypeStatus != .reachedExit,
              let landmarkID = landmarkInteractionResolver.activeLandmarkReached(
                by: playerPosition,
                in: worldState,
                mapper: mapper
              ) else {
            return
        }

        let emittedEvents = worldEventManager.handle(.landmarkReached(landmarkID), worldState: &worldState)
        for event in emittedEvents {
            queueOrPresent(event)
        }
        autosave(reason: "landmark reached")
    }

    func queueOrPresent(_ event: GameDomainEvent) {
        guard gameMode == .exploring else {
            pendingPresentationEvents.append(event)
            return
        }

        present(event)
    }

    func flushPendingPresentationEvents() {
        let events = pendingPresentationEvents
        pendingPresentationEvents.removeAll()
        for event in events {
            present(event)
        }
    }

    func present(_ event: GameDomainEvent) {
        switch event {
        case .puzzleCompleted:
            showProgressionFeedback("ROUTE COMPLETE")
        case .landmarkActivated(let landmarkID):
            if landmarkID == .outerExit {
                worldRenderer.animateLandmarkActivation(.outerExit)
            }
        case .landmarkReached(let landmarkID):
            if landmarkID == .outerExit {
                showProgressionFeedback("PROTOTYPE COMPLETE")
            }
        case .worldEventCompleted:
            break
        }
    }

    func showProgressionFeedback(_ text: String) {
        puzzleFeedbackLabel.text = text
        puzzleFeedbackLabel.removeAllActions()
        puzzleFeedbackLabel.setScale(0.8)
        puzzleFeedbackLabel.alpha = 0
        let show = SKAction.group([
            .fadeAlpha(to: 1, duration: 0.18),
            .scale(to: 1.08, duration: 0.18)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        let wait = SKAction.wait(forDuration: 1.8)
        let hide = SKAction.fadeOut(withDuration: 0.5)
        puzzleFeedbackLabel.run(.sequence([show, settle, wait, hide]))
    }

    func spawnPlayer() {
        let node = playerController.spawnPlayerNode()
        playerNode = node
        addChild(node)

        if let pendingLoadedPlayerSpatialState,
           playerController.apply(spatialState: pendingLoadedPlayerSpatialState, to: node) {
            self.pendingLoadedPlayerSpatialState = nil
        }

        cameraNode.position = node.position
    }
}

extension Set where Element == GridPosition {
    var sortedForSaveFallback: [GridPosition] {
        sorted { lhs, rhs in
            if lhs.y == rhs.y {
                return lhs.x < rhs.x
            }
            return lhs.y < rhs.y
        }
    }
}
