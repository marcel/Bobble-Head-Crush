//
//  GameViewController.swift
//  Bobble Head Crush
//
//  Created by Marcel Molina on 6/8/16.
//  Copyright (c) 2016 Marcel Molina. All rights reserved.
//
import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
  var scene: GameScene!
  var level: Level!

  var currentLevelNum = 0

  var movesLeft = 0
  var score = 0

  var tapGestureRecognizer: UITapGestureRecognizer!

  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var movesLabel: UILabel!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var gameOverPanel: UIImageView!
  @IBOutlet weak var shuffleButton: UIButton!
  @IBOutlet weak var currentLevelLabel: UILabel!

  let heHitsItDeepSound     = SKAction.playSoundFileNamed("Kuiper HR Call.wav", waitForCompletion: false)
  let grabSomePineMeatSound = SKAction.playSoundFileNamed("Grab Some Pine Meat 2.wav", waitForCompletion: false)

  lazy var backgroundMusic: AVAudioPlayer? = {
    guard let url = NSBundle.mainBundle().URLForResource("San Francisco Giants - Bye Bye Baby", withExtension: "mp3") else {
      return nil
    }
    do {
      let player = try AVAudioPlayer(contentsOfURL: url)
      player.numberOfLoops = 0
      return player
    } catch {
      return nil
    }
  }()

  override func prefersStatusBarHidden() -> Bool {
    return true
  }

  override func shouldAutorotate() -> Bool {
    return true
  }

  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return [UIInterfaceOrientationMask.Portrait, UIInterfaceOrientationMask.PortraitUpsideDown]
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    gameOverPanel.hidden = true

    // Setup view with level 1
    setupLevel(currentLevelNum)

    // Start the background music.
    backgroundMusic?.play()
  }

  func setupLevel(levelNum: Int) {
    let skView = view as! SKView
    skView.multipleTouchEnabled = false

    // Create and configure the scene.
    scene = GameScene(size: skView.bounds.size)
    scene.scaleMode = .AspectFill

    // Setup the level.
    level = Level(filename: "Level_\(levelNum)")
    scene.level = level

    scene.addTiles()
    scene.swipeHandler = handleSwipe

    gameOverPanel.hidden = true
    shuffleButton.hidden = true

    // Present the scene.
    skView.presentScene(scene)
    
    // Start the game.
    beginGame()
  }

  func beginGame() {
    movesLeft = level.maximumMoves
    score = 0
    updateLabels()
    level.resetComboMultiplier()
    scene.animateBeginGame() {
      self.shuffleButton.hidden = false
    }
    shuffle()
  }

  func shuffle() {
    scene.removeAllBobbleHeadSprites()

    let newBobbleHeads = level.shuffle()
    scene.addSpritesForBobbleHead(newBobbleHeads)
  }

  @IBAction func shuffleButtonPressed(_: AnyObject) {
    shuffle()
    decrementMoves()
  }

  func updateLabels() {
    targetLabel.text = String(format: "%ld", level.targetScore)
    movesLabel.text = String(format: "%ld", movesLeft)
    scoreLabel.text = String(format: "%ld", score)
    currentLevelLabel.text = "\(currentLevelNum) / \(NumLevels)"
  }

  func showGameOver() {
    gameOverPanel.hidden = false
    shuffleButton.hidden = true

    scene.userInteractionEnabled = false

    scene.animateGameOver() {
      self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
      self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
  }

  func hideGameOver() {
    view.removeGestureRecognizer(tapGestureRecognizer)
    tapGestureRecognizer = nil

    gameOverPanel.hidden = true
    scene.userInteractionEnabled = true

    setupLevel(currentLevelNum)
  }

  func handleSwipe(swap: Swap) {
    if let music = backgroundMusic where music.playing {
      fadeBackgroundMusicVolume()
    }

    view.userInteractionEnabled = false

    if level.isPossibleSwap(swap) {
      level.performSwap(swap)
      scene.animateSwap(swap) {
        self.handleMatches()
        self.view.userInteractionEnabled = true
      }
    } else {
      scene.animateInvalidSwap(swap) {
        self.view.userInteractionEnabled = true
      }
    }
  }

  func handleMatches() {
    let chains = level.removeMatches()
    if chains.count == 0 {
      beginNextTurn()
      return
    }
    scene.animateMatchedBobbleHeads(chains) {
      for chain in chains {
        self.score += chain.score
      }
      self.updateLabels()
      let columns = self.level.fillHoles()
      self.scene.animateFallingBobbleHeads(columns) {
        let columns = self.level.topUpBobbleHeads()
        self.scene.animateNewBobbleHeads(columns) {
          self.handleMatches()
        }
      }
    }
  }

  func decrementMoves() {
    movesLeft -= 1
    updateLabels()

    if score >= level.targetScore {
      gameOverPanel.image = UIImage(named: "LevelComplete")
      currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum+1 : 0
      scene.runAction(heHitsItDeepSound)
      showGameOver()
    } else if movesLeft == 0 {
      gameOverPanel.image = UIImage(named: "GameOver")
      scene.runAction(grabSomePineMeatSound)
      showGameOver()
    }
  }

  func beginNextTurn() {
    decrementMoves()
    level.resetComboMultiplier()
    level.detectPossibleSwaps()
    view.userInteractionEnabled = true
  }

  func fadeBackgroundMusicVolume() {
    if let music = backgroundMusic where music.volume > 0.005 {
      music.volume = music.volume - 0.005
      performSelector(#selector(GameViewController.fadeBackgroundMusicVolume), withObject: nil, afterDelay: 0.025)
    } else {
      backgroundMusic?.stop()
    }
  }
}