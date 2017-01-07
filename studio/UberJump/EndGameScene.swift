//
//  EndGameScene.swift
//  UberJump
//
//  Created by Benjamin Beltzer on 8/21/16.
//  Copyright © 2016 Benjamin Beltzer. All rights reserved.
//

import UIKit
import SpriteKit

class EndGameScene: SKScene {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // Stars
        let star = SKSpriteNode(imageNamed: "Star")
        star.position = CGPoint(x: 25, y: self.size.height-30)
        addChild(star)
        
        let starsLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        starsLabel.fontSize = 30
        starsLabel.fontColor = SKColor.whiteColor()
        starsLabel.position = CGPoint(x: 50, y: self.size.height-40)
        starsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        starsLabel.text = "X \(GameState.sharedInstance.stars)"
        addChild(starsLabel)
        
        // Score
        let scoreLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        scoreLabel.fontSize = 60
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: self.size.width / 2, y: 300)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        scoreLabel.text = "\(GameState.sharedInstance.score)"
        addChild(scoreLabel)
        
        // High Score
        let highScoreLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        highScoreLabel.fontSize = 30
        highScoreLabel.fontColor = SKColor.cyanColor()
        highScoreLabel.position = CGPoint(x: self.size.width / 2, y: 150)
        highScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        highScoreLabel.text = "High Score: \(GameState.sharedInstance.highScore)"
        addChild(highScoreLabel)
        
        // Try again
        let tryAgainLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        tryAgainLabel.fontSize = 30
        tryAgainLabel.fontColor = SKColor.whiteColor()
        tryAgainLabel.position = CGPoint(x: self.size.width / 2, y: 50)
        tryAgainLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        tryAgainLabel.text = "Tap To Try Again"
        addChild(tryAgainLabel)        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Transition back to game
        let reveal = SKTransition.fadeWithDuration(0.5)
        let gameScene = GameScene(size: self.size)
        self.view!.presentScene(gameScene, transition: reveal)
    }
    
}
