//
//  GameObjectNode.swift
//  UberJump
//
//  Created by Benjamin Beltzer on 8/19/16.
//  Copyright © 2016 Benjamin Beltzer. All rights reserved.
//

import UIKit
import SpriteKit

struct CollisionCategoryBitmask {
    static let Player: UInt32 = 0x00
    static let Star: UInt32 = 0x01
    static let Platform: UInt32 = 0x02
}

enum StarType: Int {
    case Normal = 0
    case Special
}

enum PlatformType: Int {
    case Normal = 0
    case Break
}

class GameObjectNode: SKNode {
    
    // Returns true if HUD needs updating
    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
    func checkNodeRemoval(playerY: CGFloat) {
        if playerY > self.position.y + 300.0 {
            self.removeFromParent()
        }
    }
}

class StarNode: GameObjectNode {

    var starType: StarType!
    let starSound = SKAction.playSoundFileNamed("StarPing.wav", waitForCompletion: false)
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        // Boost player up
        player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 400.0)
        
        runAction(starSound, completion: {
            self.removeFromParent()
        })
        
        GameState.sharedInstance.score += (starType == .Normal ? 20 : 100)
        GameState.sharedInstance.stars += (starType == .Normal ? 1 : 5)
        
        return true
    }
}

class PlatformNode: GameObjectNode {
    
    var platformType: PlatformType!
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        
        if player.physicsBody?.velocity.dy < 0 {
            player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 250.0)
            
            if platformType == .Break {
                self.removeFromParent()
            }
        }
        
        return false
    }
    
}