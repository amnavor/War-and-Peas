import SpriteKit


struct PhysicsCategory {
    //category is 32-bit integer, ie each bit represents a category
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1
    static let Projectile: UInt32 = 0b10
}


//operator overloading to work with x,y coordinates (vector math)
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    //converts self into unit vector of length 1
    func normalized() -> CGPoint {
        return self / length()
    }
}










class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // player sprite
    let player = SKSpriteNode(imageNamed: "Pod")
    //counter
    var monstersDestroyed = 0
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor.whiteColor()
        //player position is horizontally centered and vertically 10%
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        addChild(player)
        
        physicsWorld.gravity = CGVectorMake(0, 0) //no gravity
        //scene is delegate for physics interactions
        physicsWorld.contactDelegate = self
        
        //run "addMonster" function every 1 second
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addMonster),
                SKAction.waitForDuration(1.0)
                ])
            ))
        
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
    }
    
    
    
    
    //functions to return random values (including within a range)
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    
    
    func addMonster() {
        
        // Create monster sprite
        let monster = SKSpriteNode(imageNamed: "Tomato")
        
        //make a physics body the size of the monster
        monster.physicsBody = SKPhysicsBody(circleOfRadius: monster.size.width/4)
        //dynamic = your code controls monster, not the physics engine
        monster.physicsBody?.dynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster
        //contact is what it should notify about, and collision is what
        //it should alter movement for (ie make them bounce off)
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        // Position the monster slightly off-screen along the right edge
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        //note CGPoint is a type for x,y points
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        addChild(monster)
        
        // random speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Create the actions: move to other side of screen, then remove
        let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        
        let loseAction = SKAction.runBlock() {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        
        monster.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
    }
    
    
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        
        runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        //select touch by user
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        
        
        //check if projectile is being launched in right direction
        let projectile = SKSpriteNode(imageNamed: "Pea")
        projectile.position = player.position
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/3)
        projectile.physicsBody?.dynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        //use precise... for fast moving bodies like projectiles
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        let offset = touchLocation - projectile.position
        if (offset.x < 0) { return }
        addChild(projectile)
        
        //normalize into unit vector of length 1 and shoot off screen
        let direction = offset.normalized()
        let shootAmount = direction * 1000
        let realDest = shootAmount + projectile.position
        
        //action: shoot and remove
        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    //separate of touchesEnded method
        func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
            print("Hit")
            projectile.removeFromParent()
            monster.removeFromParent()
            monstersDestroyed++
            if (monstersDestroyed > 15) {
                let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                let gameOverScene = GameOverScene(size: self.size, won: true)
                self.view?.presentScene(gameOverScene, transition: reveal)
            }
        }
        
        
        //check if a collision of monster and projectile, then call didCollide
        func didBeginContact(contact: SKPhysicsContact) {
            var firstBody: SKPhysicsBody //lower category BitMask, like Monster
            var secondBody: SKPhysicsBody
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            
            
            /*
            *The lower category BitMask, firstBody should be the same as the Monster
            (ie also lower) and so their & result should be 1, not 0
            * & is bitwise AND operator that combines the bits of two numbers. It returns a new number whose bits are set to 1 only if the bits were equal to 1 in both input numbers
            * as! = guaranteed conversion of a value to another type
            */
            
            if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
                (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
                    projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
            }
            
        }
    }


