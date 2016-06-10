//
//  BobbleHead.swift
//  Bobble Head Crush
//
//  Created by Marcel Molina on 6/8/16.
//  Copyright © 2016 Marcel Molina. All rights reserved.
//

import SpriteKit
import GameplayKit

enum BobbleHeadType: Int, CustomStringConvertible {
  case Unknown = 0
  case Bochy, Bumgarner, Crawford, Duffy, Pagan, Panik, Pence
  case Posey, Romo, Casilla, Tomlinson, Strickland, Span, Belt, Cueto
  case Samardzija, Seagull, LouSeal

  static func random() -> BobbleHeadType {
    return BobbleHeadType(rawValue: Int(arc4random_uniform(UInt32(spriteNames.count))) + 1)!
  }

  static let spriteNames = [
    "Bochy",
    "Bumgarner",
    "Crawford",
    "Duffy",
    "Pagan",
    "Panik",
    "Pence",
    "Posey",
    "Romo",
    "Casilla",
    "Tomlinson",
    "Strickland",
    "Span",
    "Belt",
    "Cueto",
    "Samardzija",
    "Seagull",
    "LouSeal"
  ]

  var spriteName: String {
    return BobbleHeadType.spriteNames[rawValue - 1]
  }

  var description: String {
    return spriteName
  }

  var highlightedSpriteName: String {
    return spriteName + "-Highlighted"
  }
}

class RandomBobbleHeadTypePicker {
  var applicableBobbleHeads: [Int]

  init(size: Int) {
    let random   = GKRandomSource.sharedRandom()
    let range    = Array(1...BobbleHeadType.spriteNames.count)
    let shuffled = random.arrayByShufflingObjectsInArray(range) as! [Int]

    self.applicableBobbleHeads = Array(shuffled.prefix(size))
  }

  func pickRandom() -> BobbleHeadType {
    let index = Int(arc4random_uniform(UInt32(applicableBobbleHeads.count)))
    return BobbleHeadType(rawValue: applicableBobbleHeads[index])!
  }
}

func ==(lhs: BobbleHead, rhs: BobbleHead) -> Bool {
  return lhs.column == rhs.column && lhs.row == rhs.row
}

class BobbleHead: CustomStringConvertible, Hashable {
  var column: Int
  var row: Int
  let bobbleHeadType: BobbleHeadType
  var sprite: SKSpriteNode?

  init(column: Int, row: Int, bobbleHeadType: BobbleHeadType) {
    self.column = column
    self.row = row
    self.bobbleHeadType = bobbleHeadType
  }

  // MARK: - Hashable
  var hashValue: Int {
    return row*10 + column
  }

  // MARK: - CustomStringConvertible
  var description: String {
    return "type:\(bobbleHeadType) square:(\(column),\(row))"
  }
}