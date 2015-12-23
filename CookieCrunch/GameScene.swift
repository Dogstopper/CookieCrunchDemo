//
//  GameScene.swift
//  CookieCrunch
//
//  Created by Stephen Schwahn on 12/22/15.
//  Copyright (c) 2015 Stephen Schwahn. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Instance Variables
    
    var level: Level!
    
    // Sets up an injection point for a delegate that takes
    // a Swap objects and returns void
    var swipeHandler: ((Swap) -> ())?
    
    // Visual Constants
    let TileWidth: CGFloat = 32.0
    let TileHeight: CGFloat = 36.0
    
    let gameLayer = SKNode()
    let tilesLayer = SKNode()
    let cookiesLayer = SKNode()
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()

    // Control the motion of a user swiping
    var swipeFromCol: Int?
    var swipeFromRow: Int?
    
    // Highlighted Sprite to show a node is selected
    var selectionSprite = SKSpriteNode()
    
    // Preload all the sounds
    let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    
    // MARK: - Game Setup
    
    required init?(coder aDecoder : NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        addChild(background)
        addChild(gameLayer)
        gameLayer.hidden = true
        
        let layerPosition = CGPoint(
            x: -TileWidth * CGFloat(NumCols) / 2,
            y: -TileHeight * CGFloat(NumRows) / 2)
        cookiesLayer.position = layerPosition
        tilesLayer.position = layerPosition
        maskLayer.position = layerPosition
        
        cropLayer.maskNode = maskLayer
        gameLayer.addChild(tilesLayer)
        gameLayer.addChild(cropLayer)
        cropLayer.addChild(cookiesLayer)
        
        swipeFromCol = nil;
        swipeFromRow = nil;
    }
    
    func addSpritesForCookies(cookies: Set<Cookie>) {
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName);
            sprite.position = pointForColumn(cookie.col, row: cookie.row)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite
            
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.runAction(
                SKAction.sequence([
                    SKAction.waitForDuration(0.25, withRange: 0.5),
                    SKAction.group([
                        SKAction.fadeInWithDuration(0.25),
                        SKAction.scaleTo(1.0, duration: 0.25)
                        ])
                    ]))
        }
    }
    
    func addTiles() {
        for row in 0..<NumRows {
            for col in 0..<NumCols {
                if let _ = level.tileAtColumn(col, row: row) {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.position = pointForColumn(col, row: row)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
        for row in 0...NumRows {
            for column in 0...NumCols {
                let topLeft     = (column > 0) && (row < NumRows)
                                               && level.tileAtColumn(column - 1, row: row) != nil
                let bottomLeft  = (column > 0) && (row > 0)
                                               && level.tileAtColumn(column - 1, row: row - 1) != nil
                let topRight    = (column < NumCols) && (row < NumRows)
                                                        && level.tileAtColumn(column, row: row) != nil
                let bottomRight = (column < NumCols) && (row > 0)
                                                        && level.tileAtColumn(column, row: row - 1) != nil
                
                // The tile have names from 0 to 15, according to the bitmask
                let value = Int(topLeft) | Int(topRight) << 1 | Int(bottomLeft) << 2 | Int(bottomRight) << 3
                
                // Values 0 (no tile), 6 and 9 (opposite tiles are not drawn
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    print(name)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    var point = pointForColumn(column, row: row)
                    point.x -= TileWidth / 2
                    point.y -= TileHeight / 2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }

            }
        }
    }
    
    // MARK: - Game Cleanup
    
    func removeAllCookieSprites() {
        cookiesLayer.removeAllChildren()
    }
    
    // MARK: - Conversion routines
    
    func pointForColumn(col: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(col) * TileWidth + TileWidth / 2,
            y: CGFloat(row) * TileHeight + TileHeight / 2)
    }
    
    func convertPoint(point: CGPoint) -> (success: Bool, col: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumCols) * TileWidth &&
            point.y >= 0 && point.y < CGFloat(NumRows) * TileHeight {
                return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        } else {
            return (false, 0, 0)
        }
    }
    
    // MARK: - Swipe Detection and Handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch = touches.first! as UITouch
        let location = touch.locationInNode(cookiesLayer)
        
        // Check to see if we start on a valid tile. If yes, show a 
        // highlighted sprite and set the initial row/col
        let (success, col, row) = convertPoint(location)
        if success {
            if let cookie = level.cookieAtColumn(col, row: row) {
                showSelectionIndicatorForCookie(cookie)
                swipeFromCol = col
                swipeFromRow = row
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if swipeFromCol == nil { return }
        
        let touch = touches.first! as UITouch
        let location = touch.locationInNode(cookiesLayer)
        
        // Check to see if we have moved onto another valid tile.
        let (success, col, row) = convertPoint(location)
        if success {
            
            // Determine which direction we moved
            var horzDelta = 0, vertDelta = 0
            if col < swipeFromCol! {        // Swipe Left
                horzDelta = -1
            } else if col > swipeFromCol! { // Swipe Right
                horzDelta = 1
            } else if row < swipeFromRow! { // Swipe Down
                vertDelta = -1
            } else if row > swipeFromRow! { // Swipe Up
                vertDelta = 1
            }
            
            // If we have moved off of the starting tile, then attempt a swap.
            // If valid, it will proceed with the swap; otherwise, we reset
            if horzDelta != 0 || vertDelta != 0 {
                trySwapHorizontal(horizontal: horzDelta, vertical: vertDelta)
                hideSelectionIndicator()
                swipeFromCol = nil
            }
        }
    }
    
    func trySwapHorizontal(horizontal horzDelta: Int, vertical vertDelta: Int) {
        let toCol = swipeFromCol! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        
        if (toCol < 0 || toCol >= NumCols) { return }
        if (toRow < 0 || toRow >= NumRows) { return }
        
        if let toCookie = level.cookieAtColumn(toCol, row: toRow) {
            let fromCookie = level.cookieAtColumn(swipeFromCol!, row: swipeFromRow!)
            
            // Delegate back to the controller/model to determine if it is a 
            // valid swap.
            if let handler = swipeHandler {
                let swap = Swap(cookieA: fromCookie!, cookieB: toCookie)
                handler(swap)
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if (selectionSprite.parent != nil && swipeFromCol != nil) {
            hideSelectionIndicator()
        }
        swipeFromCol = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        touchesEnded(touches, withEvent: event)
    }
    
    // MARK: - Animations
    
    func animateSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: NSTimeInterval = 0.3
        
        // Create an action to move A to B
        let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
        moveA.timingMode = .EaseOut
        spriteA.runAction(moveA, completion: completion)
        
        // Create an action to move B to A
        let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
        moveB.timingMode = .EaseOut
        spriteB.runAction(moveB)
        
        // Play the swap sound
        runAction(swapSound)
    }
    
    func animateInvalidSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: NSTimeInterval = 0.2
        
        // Create an action to move A to B
        let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
        moveA.timingMode = .EaseOut
        
        // Create an action to move B to A
        let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
        moveB.timingMode = .EaseOut
        
        // Run both animations to make it move there and back again for both A and B
        spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.runAction(SKAction.sequence([moveB, moveA]))
        
        // Play the invalid sound effect
        runAction(invalidSwapSound)
    }
    
    func animateMatchedCookies(chains: Set<Chain>, completion: () -> ()) {
        
        // For every cookie in the set of chains
        for chain in chains {
            
            animateScoreForChain(chain)
            
            for cookie in chain.cookies {
                if let sprite = cookie.sprite {
                    // If we are not already animating this cookie...
                    if sprite.actionForKey("removing") == nil {
                        // Scale and then remove animation.
                        let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
                        scaleAction.timingMode = .EaseOut
                        
                        // Tag the animation so it won't happen more than once
                        sprite.runAction(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                            withKey: "removing")
                    }
                }
            }
        }
        
        // Play the cha ching sound
        runAction(matchSound)
        
        // Wait for the animations above to finish before we give control back to 
        // the Game
        runAction(SKAction.waitForDuration(0.3), completion: completion)
    }
    
    func animateFallingCookies(columns: [[Cookie]], completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        
        // For every cookie that needs to fall
        for array in columns {
            for (idx, cookie) in array.enumerate() {
                
                // Calculate the new position, set up animations
                let newPosition = pointForColumn(cookie.col, row: cookie.row)
                let delay = 0.05 + 0.15 * NSTimeInterval(idx) // Don't want them all falling at once. :)
                let sprite = cookie.sprite!
                let duration = NSTimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.1) // Let it fall as far as it goes
                
                // We need to wait the absolute longest amount of time before handing control back to the game
                longestDuration = max(longestDuration, duration + delay)
                
                // Run the animations after a delay for each cookie, and when it falls, play a sound.
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        SKAction.group([moveAction, fallingCookieSound])]))
            }
        }
        
        // Wait until all the blocks have fallen.
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateNewCookies(columns: [[Cookie]], completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        
        for array in columns {
            // The sprite needs to start above the first tile in the column.
            let rowStart = array[0].row + 1
            
            for (i, cookie) in array.enumerate() {
                // Creat and add the new sprite onto the screen
                let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
                sprite.position = pointForColumn(cookie.col, row: rowStart)
                cookiesLayer.addChild(sprite)
                cookie.sprite = sprite
                
                // Set the delay for each tile to wait until the previous is out of the way
                let delay = 0.1 + 0.2 * NSTimeInterval(array.count - i - 1)
                
                // Calculate the duration similarly
                let duration = NSTimeInterval(rowStart - cookie.row) * 0.1
                longestDuration = max(duration, longestDuration)
                
                // Create and run the animations
                let newPosition = pointForColumn(cookie.col, row: cookie.row)
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.alpha = 0
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        SKAction.group([
                            SKAction.fadeInWithDuration(0.05),
                            moveAction,
                            addCookieSound])
                        ]))
            }
        }
        
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }

    func animateScoreForChain(chain: Chain) {
        // Figure out what the midpoint of the chain is
        let firstSprite = chain.firstCookie().sprite!
        let lastSprite = chain.lastCookie().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)
        
        // Add a label for the score that slowly floats up
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        cookiesLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .EaseOut
        scoreLabel.runAction(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    func animateGameOver(completion: () -> ()) {
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseIn
        gameLayer.runAction(action, completion: completion)
    }
    
    func animateBeginGame(completion: () -> ()) {
        gameLayer.hidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseOut
        gameLayer.runAction(action, completion: completion)
    }
    
    // MARK: - Selection Indicators
    
    func showSelectionIndicatorForCookie(cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
            selectionSprite.size = texture.size()
            selectionSprite.runAction(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.runAction(SKAction.sequence([
            SKAction.fadeOutWithDuration(0.3),
            SKAction.removeFromParent()]))
    }
    
}
