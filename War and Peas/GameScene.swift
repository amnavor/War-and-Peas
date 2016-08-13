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
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
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
        
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        //select touch by user
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        
        
        //check if projectile is being launched in right direction
        let projectile = SKSpriteNode(imageNamed: "Pea")
        projectile.position = player.position
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
}

