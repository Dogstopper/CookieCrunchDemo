//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Stephen Schwahn on 12/22/15.
//  Copyright (c) 2015 Stephen Schwahn. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    
    // MARK: - Instance Variables
    
    var scene : GameScene!
    var level : Level!
    
    var levelNum = 0
    var movesLeft = 0
    var score = 0
    
    @IBOutlet weak var targetLabel : UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameOverPanel: UIImageView!
    @IBOutlet weak var shuffleButton: UIButton!
    
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    lazy var backgroundMusic: AVAudioPlayer? = {
        do {
            let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: ".mp3");
            let player = try AVAudioPlayer(contentsOfURL: url!)
            player.numberOfLoops = -1
            return player
        } catch {
            // TODO: Handle this
            return nil
        }
    }()
    
    // MARK: - ViewController Configuration

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Setup the View

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Load the level.
        beginGame()
    }
    
    private func setupView() {
        // Configure the view
        let skView = view as! SKView
        skView.multipleTouchEnabled = false;
        
        // Create and configure the scene
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        level = Level(filename: String(format: "Level_%ld", levelNum))
        scene.level = level
        
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        // Hide the game over image
        gameOverPanel.hidden = true
        
        // Present the scene and begin
        skView.presentScene(scene)
        backgroundMusic?.play()

    }
    
    // MARK: - Game Control
    
    func beginGame() {
        setupView()
        
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
        level.resetComboMultiplier()
        
        scene.animateBeginGame({
            self.shuffleButton.hidden = false
        })
        
        shuffle()
    }
    
    func shuffle() {
        scene.removeAllCookieSprites()
        let newCookies = level.shuffle();
        scene.addSpritesForCookies(newCookies)
    }
    
    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        view.userInteractionEnabled = true
        decrementMoves()
    }
    
    func decrementMoves() {
        --movesLeft
        updateLabels()
        
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            showGameOver()
            ++levelNum
        } else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
        }
    }
    
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
    }
    
    func showGameOver() {
        gameOverPanel.hidden = false
        scene.userInteractionEnabled = false
        shuffleButton.hidden = true
        
        scene.animateGameOver({
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideGameOver")
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        })
    }
    
    func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.hidden = true
        scene.userInteractionEnabled = true
        
        beginGame()
    }
    
    @IBAction func shuffleButtonPressed(_: AnyObject) {
        shuffle()
        decrementMoves()
    }
    
    // MARK: - Delegates
    
    func handleSwipe(swap: Swap) {
        view.userInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
            
        } else {
            scene.animateInvalidSwap(swap, completion: {
                self.view.userInteractionEnabled = true
            })
        }
    }
    
    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        scene.animateMatchedCookies(chains, completion: {
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns, completion: {
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns, completion: {
                    // Recurse to handle any new matches that may occur
                    self.handleMatches()
                })
            })
        })
    }
}
