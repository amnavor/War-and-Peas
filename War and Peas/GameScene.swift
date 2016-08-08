import SpriteKit

class GameScene: SKScene {
    
    // player sprite
    let player = SKSpriteNode(imageNamed: "Pod")
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor.whiteColor()
        //player position is horizontally centered and vertically 10%
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        addChild(player)
    }
}