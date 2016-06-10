//
//  Chain.swift
//  Bobble Head Crush
//
//  Created by Marcel Molina on 6/9/16.
//  Copyright © 2016 Marcel Molina. All rights reserved.
//

class Chain: Hashable, CustomStringConvertible {
  var bobbleHeads = [BobbleHead]()
  var score = 0


  enum ChainType: CustomStringConvertible {
    case Horizontal
    case Vertical
    case Overlapping

    var description: String {
      switch self {
      case .Horizontal: return "Horizontal"
      case .Vertical: return "Vertical"
      case .Overlapping: return "Overlapping"
      }
    }
  }

  var chainType: ChainType

  init(chainType: ChainType) {
    self.chainType = chainType
  }

  func addBobbleHead(bobbleHead: BobbleHead) {
    bobbleHeads.append(bobbleHead)
  }

  func firstBobbleHead() -> BobbleHead {
    return bobbleHeads[0]
  }

  func lastBobbleHead() -> BobbleHead {
    return bobbleHeads[bobbleHeads.count - 1]
  }

  var length: Int {
    return bobbleHeads.count
  }

  var description: String {
    return "type:\(chainType) bobbleHeads:\(bobbleHeads)"
  }

  var hashValue: Int {
    return bobbleHeads.reduce(0) { $0.hashValue ^ $1.hashValue }
  }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
  return lhs.bobbleHeads == rhs.bobbleHeads
}
