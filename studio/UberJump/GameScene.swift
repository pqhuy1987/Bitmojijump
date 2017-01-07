//
//  GameScene.swift
//  UberJump
//
//  Created by Benjamin Beltzer on 8/18/16.
//  Copyright (c) 2016 Benjamin Beltzer. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene {

    // Layered Nodes
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    var player: SKNode!
    
    // To Accommodate iPhone 6
    var scaleFactor: CGFloat!
    
    // Tap to start
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    
    // Height at which level ends
    var endLevelY = 0
    
    // Motion manager for accelerometer
    let motionManager = CMMotionManager()
    
    // Acceleration value from accelerometer
    var xAcceleration: CGFloat = 0.0
    
    // Labels for score and stars
    var scoreLabel: SKLabelNode!
    var starsLabel: SKLabelNode!
    
    // Max y reached by player
    var maxPlayerY: Int!
    
    var gameOver = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.whiteColor()
        
        maxPlayerY = 80 // initial player starting position
        GameState.sharedInstance.score = 0
        GameState.sharedInstance.stars = 0
        gameOver = false
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self
        
        scaleFactor = self.size.width / 320.0
        
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
        
        midgroundNode = createMidgroundNode()
        addChild(midgroundNode)
        
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        hudNode = SKNode()
        addChild(hudNode)
        
        // Load Level
        let levelPlist = NSBundle.mainBundle().pathForResource("Level01", ofType: "plist")
        let levelData = NSDictionary(contentsOfFile: levelPlist!)!
        
        // Height at which player ends level
        endLevelY = levelData["EndY"]!.integerValue!
        
        // Add level objects
        createPlatforms(levelData)
        createStars(levelData)
        
        player = createPlayer()
        foregroundNode.addChild(player)
        
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: 180.0)
        hudNode.addChild(tapToStartNode)
        
        // build HUD
        buildHUD()
        
        // CoreMotion
        motionManager.accelerometerUpdateInterval = 0.2
        
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: {
            (accelerometerData: CMAccelerometerData?, error: NSError?) in
            let acceleration = accelerometerData!.acceleration
            self.xAcceleration = (CGFloat(acceleration.x) * 0.85) + (self.xAcceleration * 0.15)
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if player.physicsBody!.dynamic {
            return
        }
        
        tapToStartNode.removeFromParent()
        
        player.physicsBody?.dynamic = true
        
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 20.0))
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        // update max height
        if Int(player.position.y) > maxPlayerY {
            GameState.sharedInstance.score += Int(player.position.y) - maxPlayerY
            maxPlayerY = Int(player.position.y)
            scoreLabel.text = "\(GameState.sharedInstance.score)"
        }
        
        // Remove game objects that have passed by
        foregroundNode.enumerateChildNodesWithName("NODE_PLATFORM", usingBlock: {
            (node, stop) in
            let platform = node as! PlatformNode
            platform.checkNodeRemoval(self.player.position.y)
        })
        
        foregroundNode.enumerateChildNodesWithName("NODE_STAR", usingBlock: {
            (node, stop) in
            let star = node as! StarNode
            star.checkNodeRemoval(self.player.position.y)
        })
        
        // Calculate player y offset
        if player.position.y > 200.0 {
            backgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0)/10))
            midgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0)/4))
            foregroundNode.position = CGPoint(x: 0.0, y: -(player.position.y - 200.0))
        }
        
        // Check if game over
        if Int(player.position.y) > endLevelY {
            endGame()
        }
        
        if Int(player.position.y) < maxPlayerY - 800 {
            endGame()
        }
        
        if gameOver {
            return
        }
    }
    
    override func didSimulatePhysics() {
        
        // Set velocity based on x-axis acceleration
        player.physicsBody?.velocity = CGVector(dx: xAcceleration * 400.0, dy: player.physicsBody!.velocity.dy)
        
        // Check x bounds
        if player.position.x < -20.0 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        } else if (player.position.x > self.size.width + 20) {
            player.position = CGPoint(x: -20.0, y: player.position.y)
        }
    }
    
    // MARK: Layer Methods
    
    func createBackgroundNode() -> SKNode {
        
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        for index in 0...19 {
            let node = SKSpriteNode(imageNamed: String(format: "Background%02d", index + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width/2, y: ySpacing * CGFloat(index))
            
            backgroundNode.addChild(node)
        }
        
        return backgroundNode
    }
    
    func createMidgroundNode() -> SKNode {

        // Create node
        let midgroundNode = SKNode()
        var anchor: CGPoint!
        var xPosition: CGFloat!
        
        // Add branches to midground
        for index in 0...9 {
            var spriteName: String
            let r = arc4random() % 2
            if r > 0 {
                spriteName = "BranchRight"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = self.size.width
            } else {
                spriteName = "BranchLeft"
                anchor = CGPoint(x: 0.0, y: 0.5)
                xPosition  = 0.0
            }
            
            let branchNode = SKSpriteNode(imageNamed: spriteName)
            branchNode.anchorPoint = anchor
            branchNode.position = CGPoint(x: xPosition, y: 500.0 * CGFloat(index))
            midgroundNode.addChild(branchNode)
        }
        
        return midgroundNode
    }
    
    // MARK: Game Object Creation Methods
    
    func createPlayer() -> SKNode {
        
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: 80.0)
        
        let sprite = SKSpriteNode(imageNamed: "Player")
        playerNode.addChild(sprite)
        
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        playerNode.physicsBody?.dynamic = false
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 1.0
        playerNode.physicsBody?.friction = 0.0
        playerNode.physicsBody?.angularDamping = 0.0
        playerNode.physicsBody?.linearDamping = 0.0
        
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Player
        playerNode.physicsBody?.collisionBitMask = 0
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Star | CollisionCategoryBitmask.Platform
        
        return playerNode
    }
    
    func createStarAtPosition(position: CGPoint, ofType type: StarType) -> StarNode {
        
        let node = StarNode()
        node.position = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.name = "NODE_STAR"
        node.starType = type
        
        var sprite: SKSpriteNode
        if type == .Special {
            sprite = SKSpriteNode(imageNamed: "StarSpecial")
        } else{
            sprite = SKSpriteNode(imageNamed: "Star")
        }
        node.addChild(sprite)
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        
        node.physicsBody?.dynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Star
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    func createPlatformNodeAtPosition(position: CGPoint, ofType type: PlatformType) -> PlatformNode {
        
        let node = PlatformNode()
        node.position = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.name = "NODE_PLATFORM"
        node.platformType = type
        
        var sprite: SKSpriteNode
        if type == .Break {
            sprite = SKSpriteNode(imageNamed: "PlatformBreak")
        } else {
            sprite = SKSpriteNode(imageNamed: "Platform")
        }
        node.addChild(sprite)
        
        node.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        node.physicsBody?.dynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Platform
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    func createPlatforms(levelData: NSDictionary) {

        let platforms = levelData["Platforms"] as! NSDictionary
        let platformPatterns = platforms["Patterns"] as! NSDictionary
        let platformPositions = platforms["Positions"] as! [NSDictionary]

        for platformPosition in platformPositions {
            let patternX = platformPosition["x"]?.floatValue
            let patternY = platformPosition["y"]?.floatValue
            let pattern = platformPosition["pattern"] as! NSString
            
            let platformPattern = platformPatterns[pattern] as! [NSDictionary]
            for platformPoint in platformPattern {
                let x = platformPoint["x"]?.floatValue
                let y = platformPoint["y"]?.floatValue
                let type = PlatformType(rawValue: platformPoint["type"]!.integerValue)
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                let platformNode = createPlatformNodeAtPosition(CGPoint(x: positionX, y: positionY), ofType: type!)
                foregroundNode.addChild(platformNode)
            }
        }
    }
    
    func createStars(levelData: NSDictionary) {
      
        let stars = levelData["Stars"] as! NSDictionary
        let starPatterns = stars["Patterns"] as! NSDictionary
        let starPositions = stars["Positions"] as! [NSDictionary]
        
        for starPosition in starPositions {
            let patternX = starPosition["x"]?.floatValue
            let patternY = starPosition["y"]?.floatValue
            let pattern = starPosition["pattern"] as! NSString
            
            // Look up the pattern
            let starPattern = starPatterns[pattern] as! [NSDictionary]
            for starPoint in starPattern {
                let x = starPoint["x"]?.floatValue
                let y = starPoint["y"]?.floatValue
                let type = StarType(rawValue: starPoint["type"]!.integerValue)
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                let starNode = createStarAtPosition(CGPoint(x: positionX, y: positionY), ofType: type!)
                foregroundNode.addChild(starNode)
            }
        }
    }
    
    func buildHUD() {

        let star = SKSpriteNode(imageNamed: "Star")
        star.position = CGPoint(x: 25, y: self.size.height - 30)
        hudNode.addChild(star)
        
        starsLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        starsLabel.fontSize = 30
        starsLabel.fontColor = SKColor.whiteColor()
        starsLabel.position = CGPoint(x: 50, y: self.size.height - 40)
        starsLabel.horizontalAlignmentMode = .Left
        starsLabel.text = "X \(GameState.sharedInstance.stars)"
        hudNode.addChild(starsLabel)
        
        scoreLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: self.size.width-20, y: self.size.height-40)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        scoreLabel.text = "0"
        hudNode.addChild(scoreLabel)
    }

    func endGame() {
        
        gameOver = true
        GameState.sharedInstance.saveState()
        
        let reveal = SKTransition.fadeWithDuration(0.5)
        let endGameScene = EndGameScene(size: self.size)
        self.view!.presentScene(endGameScene, transition: reveal)
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        var updateHUD = false
        
        let nonPlayerNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let other = nonPlayerNode as! GameObjectNode
        
        updateHUD = other.collisionWithPlayer(player)
        
        if updateHUD {
            starsLabel.text = "X \(GameState.sharedInstance.stars)"
            scoreLabel.text = "\(GameState.sharedInstance.score)"
        }
    }
    
}