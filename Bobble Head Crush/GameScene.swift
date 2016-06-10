//
//  GameScene.swift
//  Bobble Head Crush
//
//  Created by Marcel Molina on 6/8/16.
//  Copyright (c) 2016 Marcel Molina. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  var level: Level!

  let TileWidth: CGFloat  = 44.0
  let TileHeight: CGFloat = 44.0

  let gameLayer = SKNode()
  let bobbleHeadsLayer = SKNode()
  let tilesLayer = SKNode()
  let cropLayer = SKCropNode()
  let maskLayer = SKNode()

  var selectionSprite = SKSpriteNode()

  var swipeFromColumn: Int?
  var swipeFromRow: Int?

  var swipeHandler: ((Swap) -> ())?

  let swapSound = SKAction.playSoundFileNamed("Baseball Hitting Bat.wav", waitForCompletion: false)
  let invalidSwapSound = SKAction.playSoundFileNamed("Whiff.wav", waitForCompletion: false)
  let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
  let fallingBobbleHeadSound = SKAction.playSoundFileNamed("Ball Hitting Glove.wav", waitForCompletion: false)
  let addBobbleHeadSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder) is not used in this app")
  }

  override init(size: CGSize) {
    super.init(size: size)

    swipeFromColumn = nil
    swipeFromRow    = nil

    anchorPoint = CGPoint(x: 0.5, y: 0.5)

    let background = SKSpriteNode(imageNamed: "Background")
    background.size = size
    addChild(background)

    addChild(gameLayer)

    let layerPosition = CGPoint(
      x: -TileWidth * CGFloat(NumColumns) / 2,
      y: -TileHeight * CGFloat(NumRows) / 2
    )

    tilesLayer.position = layerPosition
    gameLayer.addChild(tilesLayer)

    gameLayer.addChild(cropLayer)

    maskLayer.position = layerPosition
    cropLayer.maskNode = maskLayer

    bobbleHeadsLayer.position = layerPosition
    cropLayer.addChild(bobbleHeadsLayer)

    // Preload the font so it's cached
    let _ = SKLabelNode(fontNamed: "GillSans-BoldItalic")
  }

  func addSpritesForBobbleHead(bobbleHeads: Set<BobbleHead>) {
    for bobbleHead in bobbleHeads {
      let sprite = SKSpriteNode(imageNamed: bobbleHead.bobbleHeadType.spriteName)
      sprite.size = CGSize(width: TileWidth, height: TileHeight)
      sprite.position = pointForColumn(bobbleHead.column, row: bobbleHead.row)
      bobbleHeadsLayer.addChild(sprite)
      bobbleHead.sprite = sprite
      // Give each cookie sprite a small, random delay. Then fade them in.
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
      for column in 0..<NumColumns {
        if level.tileAtColumn(column, row: row) != nil {
          let tileNode = SKSpriteNode(imageNamed: "MaskTile")
          tileNode.size = CGSize(width: TileWidth, height: TileHeight)
          tileNode.position = pointForColumn(column, row: row)
          maskLayer.addChild(tileNode)
        }
      }
    }

    for row in 0...NumRows {
      for column in 0...NumColumns {
        let topLeft     = (column > 0) && (row < NumRows)
          && level.tileAtColumn(column - 1, row: row) != nil
        let bottomLeft  = (column > 0) && (row > 0)
          && level.tileAtColumn(column - 1, row: row - 1) != nil
        let topRight    = (column < NumColumns) && (row < NumRows)
          && level.tileAtColumn(column, row: row) != nil
        let bottomRight = (column < NumColumns) && (row > 0)
          && level.tileAtColumn(column, row: row - 1) != nil

        // The tiles are named from 0 to 15, according to the bitmask that is
        // made by combining these four values.
        let value = Int(topLeft) | Int(topRight) << 1 | Int(bottomLeft) << 2 | Int(bottomRight) << 3

        // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
        if value != 0 && value != 6 && value != 9 {
          let name = String(format: "Tile_%ld", value)
          let tileNode = SKSpriteNode(imageNamed: name)
          tileNode.size = CGSize(width: TileWidth, height: TileHeight)
          var point = pointForColumn(column, row: row)
          point.x -= TileWidth/2
          point.y -= TileHeight/2
          tileNode.position = point
          tilesLayer.addChild(tileNode)
        }
      }
    }
  }

  func showSelectionIndicatorForBobbleHead(bobbleHead: BobbleHead) {
    if selectionSprite.parent != nil {
      selectionSprite.removeFromParent()
    }

    if let sprite = bobbleHead.sprite {
      let texture = SKTexture(imageNamed: bobbleHead.bobbleHeadType.highlightedSpriteName)
      selectionSprite.size = CGSize(width: TileWidth, height: TileHeight)
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

  func pointForColumn(column: Int, row: Int) -> CGPoint {
    return CGPoint(
      x: CGFloat(column)*TileWidth + TileWidth/2,
      y: CGFloat(row)*TileHeight + TileHeight/2)
  }

  func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
    if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
      point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
      return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
    } else {
      return (false, 0, 0)  // invalid location
    }
  }

  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    // 1
    guard let touch = touches.first else { return }

    let location = touch.locationInNode(bobbleHeadsLayer)
    // 2
    let (success, column, row) = convertPoint(location)
    if success {
      // 3
      if let bobbleHead = level.bobbleHeadAtColumn(column, row: row) {
        // 4
        swipeFromColumn = column
        swipeFromRow = row
        showSelectionIndicatorForBobbleHead(bobbleHead)
      }
    }
  }

  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    // 1
    guard swipeFromColumn != nil else { return }

    // 2
    guard let touch = touches.first else { return }
    let location = touch.locationInNode(bobbleHeadsLayer)

    let (success, column, row) = convertPoint(location)
    if success {

      // 3
      var horzDelta = 0, vertDelta = 0
      if column < swipeFromColumn! {          // swipe left
        horzDelta = -1
      } else if column > swipeFromColumn! {   // swipe right
        horzDelta = 1
      } else if row < swipeFromRow! {         // swipe down
        vertDelta = -1
      } else if row > swipeFromRow! {         // swipe up
        vertDelta = 1
      }

      // 4
      if horzDelta != 0 || vertDelta != 0 {
        trySwapHorizontal(horzDelta, vertical: vertDelta)
        hideSelectionIndicator()
        // 5
        swipeFromColumn = nil
      }
    }
  }

  func trySwapHorizontal(horzDelta: Int, vertical vertDelta: Int) {
    // 1
    let toColumn = swipeFromColumn! + horzDelta
    let toRow = swipeFromRow! + vertDelta
    // 2
    guard toColumn >= 0 && toColumn < NumColumns else { return }
    guard toRow >= 0 && toRow < NumRows else { return }
    // 3
    if let toBobbleHead = level.bobbleHeadAtColumn(toColumn, row: toRow),
      let fromBobbleHead = level.bobbleHeadAtColumn(swipeFromColumn!, row: swipeFromRow!) {
      // 4
      if let handler = swipeHandler {
        let swap = Swap(bobbleHeadA: fromBobbleHead, bobbleHeadB: toBobbleHead)
        handler(swap)
      }
    }
  }

  func animateSwap(swap: Swap, completion: () -> ()) {
    let spriteA = swap.bobbleHeadA.sprite!
    let spriteB = swap.bobbleHeadB.sprite!

    spriteA.zPosition = 100
    spriteB.zPosition = 90

    let Duration: NSTimeInterval = 0.3

    let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
    moveA.timingMode = .EaseOut
    spriteA.runAction(moveA, completion: completion)

    let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
    moveB.timingMode = .EaseOut
    spriteB.runAction(moveB)
    runAction(swapSound)
  }

  func animateInvalidSwap(swap: Swap, completion: () -> ()) {
    let spriteA = swap.bobbleHeadA.sprite!
    let spriteB = swap.bobbleHeadB.sprite!

    spriteA.zPosition = 100
    spriteB.zPosition = 90

    let Duration: NSTimeInterval = 0.2

    let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
    moveA.timingMode = .EaseOut

    let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
    moveB.timingMode = .EaseOut

    spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
    spriteB.runAction(SKAction.sequence([moveB, moveA]))

    runAction(invalidSwapSound)
  }

  func animateMatchedBobbleHeads(chains: Set<Chain>, completion: () -> ()) {
    for chain in chains {
      animateScoreForChain(chain)
      for bobbleHead in chain.bobbleHeads {
        if let sprite = bobbleHead.sprite {
          if sprite.actionForKey("removing") == nil {
            let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
            scaleAction.timingMode = .EaseOut
            sprite.runAction(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                             withKey:"removing")
          }
        }
      }
    }
    runAction(matchSound)
    runAction(SKAction.waitForDuration(0.3), completion: completion)
  }

  func animateFallingBobbleHeads(columns: [[BobbleHead]], completion: () -> ()) {
    // 1
    var longestDuration: NSTimeInterval = 0
    for array in columns {
      for (idx, bobbleHead) in array.enumerate() {
        let newPosition = pointForColumn(bobbleHead.column, row: bobbleHead.row)
        // 2
        let delay = 0.05 + 0.15*NSTimeInterval(idx)
        // 3
        let sprite = bobbleHead.sprite!
        let duration = NSTimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.1)
        // 4
        longestDuration = max(longestDuration, duration + delay)
        // 5
        let moveAction = SKAction.moveTo(newPosition, duration: duration)
        moveAction.timingMode = .EaseOut
        sprite.runAction(
          SKAction.sequence([
            SKAction.waitForDuration(delay),
            SKAction.group([moveAction, fallingBobbleHeadSound])]))
      }
    }
    // 6
    runAction(SKAction.waitForDuration(longestDuration), completion: completion)
  }

  func animateNewBobbleHeads(columns: [[BobbleHead]], completion: () -> ()) {
    // 1
    var longestDuration: NSTimeInterval = 0

    for array in columns {
      // 2
      let startRow = array[0].row + 1

      for (idx, bobbleHead) in array.enumerate() {
        // 3
        let sprite = SKSpriteNode(imageNamed: bobbleHead.bobbleHeadType.spriteName)
        sprite.size = CGSize(width: TileWidth, height: TileHeight)
        sprite.position = pointForColumn(bobbleHead.column, row: startRow)
        bobbleHeadsLayer.addChild(sprite)
        bobbleHead.sprite = sprite
        // 4
        let delay = 0.1 + 0.2 * NSTimeInterval(array.count - idx - 1)
        // 5
        let duration = NSTimeInterval(startRow - bobbleHead.row) * 0.1
        longestDuration = max(longestDuration, duration + delay)
        // 6
        let newPosition = pointForColumn(bobbleHead.column, row: bobbleHead.row)
        let moveAction = SKAction.moveTo(newPosition, duration: duration)
        moveAction.timingMode = .EaseOut
        sprite.alpha = 0
        sprite.runAction(
          SKAction.sequence([
            SKAction.waitForDuration(delay),
            SKAction.group([
              SKAction.fadeInWithDuration(0.05),
              moveAction,
              addBobbleHeadSound])
            ]))
      }
    }
    // 7
    runAction(SKAction.waitForDuration(longestDuration), completion: completion)
  }

  func animateScoreForChain(chain: Chain) {
    // Figure out what the midpoint of the chain is.
    let firstSprite = chain.firstBobbleHead().sprite!
    let lastSprite = chain.lastBobbleHead().sprite!
    let centerPosition = CGPoint(
      x: (firstSprite.position.x + lastSprite.position.x)/2,
      y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)

    // Add a label for the score that slowly floats up.
    let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
    scoreLabel.fontSize = 16
    scoreLabel.text = String(format: "%ld", chain.score)
    scoreLabel.position = centerPosition
    scoreLabel.zPosition = 300
    bobbleHeadsLayer.addChild(scoreLabel)

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

  func removeAllBobbleHeadSprites() {
    bobbleHeadsLayer.removeAllChildren()
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if selectionSprite.parent != nil && swipeFromColumn != nil {
      hideSelectionIndicator()
    }
    swipeFromColumn = nil
    swipeFromRow = nil
  }

  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    if let touches = touches {
      touchesEnded(touches, withEvent: event)
    }
  }
}