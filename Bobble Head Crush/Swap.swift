//
//  Swap.swift
//  Bobble Head Crush
//
//  Created by Marcel Molina on 6/9/16.
//  Copyright © 2016 Marcel Molina. All rights reserved.
//

func ==(lhs: Swap, rhs: Swap) -> Bool {
  return (lhs.bobbleHeadA == rhs.bobbleHeadA && lhs.bobbleHeadB == rhs.bobbleHeadB) ||
    (lhs.bobbleHeadB == rhs.bobbleHeadA && lhs.bobbleHeadA == rhs.bobbleHeadB)
}

struct Swap: CustomStringConvertible, Hashable {
  let bobbleHeadA: BobbleHead
  let bobbleHeadB: BobbleHead

  init(bobbleHeadA: BobbleHead, bobbleHeadB: BobbleHead) {
    self.bobbleHeadA = bobbleHeadA
    self.bobbleHeadB = bobbleHeadB
  }

  var hashValue: Int {
    return bobbleHeadA.hashValue ^ bobbleHeadB.hashValue
  }

  var description: String {
    return "swap \(bobbleHeadA) with \(bobbleHeadB)"
  }
}