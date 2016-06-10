//
//  Level.swift
//  Bobble Head Crush
//
//  Created by Marcel Molina on 6/8/16.
//  Copyright © 2016 Marcel Molina. All rights reserved.
//

import Foundation

let NumColumns = 7
let NumRows    = 9
let BobbleHeadTypesPerLevel = 6
let NumLevels = 17 // Excluding level 0

class Level {
  private var bobbleHeads = Array2D<BobbleHead>(columns: NumColumns, rows: NumRows)
  private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
  private let picker = RandomBobbleHeadTypePicker(size: BobbleHeadTypesPerLevel)
  private var possibleSwaps = Set<Swap>()

  var targetScore = 0
  var maximumMoves = 0
  private var comboMultiplier = 0

  init(filename: String) {
    // 1
    guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename) else { return }
    // 2
    guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
    // 3
    for (row, rowArray) in tilesArray.enumerate() {
      // 4
      let tileRow = NumRows - row - 1
      // 5
      for (column, value) in rowArray.enumerate() {
        if value == 1 {
          tiles[column, tileRow] = Tile()
        }
      }
    }
    targetScore = dictionary["targetScore"] as! Int
    maximumMoves = dictionary["moves"] as! Int
  }

  func performSwap(swap: Swap) {
    let columnA = swap.bobbleHeadA.column
    let rowA = swap.bobbleHeadA.row
    let columnB = swap.bobbleHeadB.column
    let rowB = swap.bobbleHeadB.row

    bobbleHeads[columnA, rowA] = swap.bobbleHeadB
    swap.bobbleHeadB.column = columnA
    swap.bobbleHeadB.row = rowA

    bobbleHeads[columnB, rowB] = swap.bobbleHeadA
    swap.bobbleHeadA.column = columnB
    swap.bobbleHeadA.row = rowB
  }

  func bobbleHeadAtColumn(column: Int, row: Int) -> BobbleHead? {
    assert(column >= 0 && column < NumColumns)
    assert(row >= 0 && row < NumRows)
    return bobbleHeads[column, row]
  }

  func shuffle() -> Set<BobbleHead> {
    var set: Set<BobbleHead>
    repeat {
      set = createInitialBobbleHeads()
      detectPossibleSwaps()
      print("possible swaps: \(possibleSwaps)")
    } while possibleSwaps.count == 0

    return set
  }

  func isPossibleSwap(swap: Swap) -> Bool {
    return possibleSwaps.contains(swap)
  }

  func detectPossibleSwaps() {
    var set = Set<Swap>()

    for row in 0..<NumRows {
      for column in 0..<NumColumns {
        if let bobbleHead = bobbleHeads[column, row] {

          // Is it possible to swap this bobbleHead with the one on the right?
          if column < NumColumns - 1 {
            // Have a bobbleHead in this spot? If there is no tile, there is no bobbleHead.
            if let other = bobbleHeads[column + 1, row] {
              // Swap them
              bobbleHeads[column, row] = other
              bobbleHeads[column + 1, row] = bobbleHead

              // Is either bobbleHead now part of a chain?
              if hasChainAtColumn(column + 1, row: row) ||
                hasChainAtColumn(column, row: row) {
                set.insert(Swap(bobbleHeadA: bobbleHead, bobbleHeadB: other))
              }
              
              // Swap them back
              bobbleHeads[column, row] = bobbleHead
              bobbleHeads[column + 1, row] = other
            }
          }

          if row < NumRows - 1 {
            if let other = bobbleHeads[column, row + 1] {
              bobbleHeads[column, row] = other
              bobbleHeads[column, row + 1] = bobbleHead

              // Is either booblehead now part of a chain?
              if hasChainAtColumn(column, row: row + 1) ||
                hasChainAtColumn(column, row: row) {
                set.insert(Swap(bobbleHeadA: bobbleHead, bobbleHeadB: other))
              }

              // Swap them back
              bobbleHeads[column, row] = bobbleHead
              bobbleHeads[column, row + 1] = other
            }
          }
        }
      }
    }
    
    possibleSwaps = set
  }

  private func calculateScores(chains: Set<Chain>) {
    // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
    for chain in chains {
      chain.score = 60 * (chain.length - 2) * comboMultiplier
      comboMultiplier += 1
    }
  }

  func resetComboMultiplier() {
    comboMultiplier = 1
  }

  func removeMatches() -> Set<Chain> {
    let horizontalChains = detectHorizontalMatches()
    let verticalChains   = detectVerticalMatches()

    print("Horizontal matches: \(horizontalChains)")
    print("Vertical matches: \(verticalChains)")

    removeBobbleHeads(horizontalChains)
    removeBobbleHeads(verticalChains)

    calculateScores(horizontalChains)
    calculateScores(verticalChains)

    return horizontalChains.union(verticalChains)
  }

  private func detectHorizontalMatches() -> Set<Chain> {
    // 1
    var set = Set<Chain>()
    // 2
    for row in 0..<NumRows {
      var column = 0
      while column < NumColumns-2 {
        // 3
        if let bobbleHead = bobbleHeads[column, row] {
          let matchType = bobbleHead.bobbleHeadType
          // 4
          if bobbleHeads[column + 1, row]?.bobbleHeadType == matchType &&
            bobbleHeads[column + 2, row]?.bobbleHeadType == matchType {
            // 5
            let chain = Chain(chainType: .Horizontal)
            repeat {
              chain.addBobbleHead(bobbleHeads[column, row]!)
              column += 1
            } while column < NumColumns && bobbleHeads[column, row]?.bobbleHeadType == matchType

            set.insert(chain)
            continue
          }
        }
        // 6
        column += 1
      }
    }
    return set
  }

  private func detectVerticalMatches() -> Set<Chain> {
    var set = Set<Chain>()

    for column in 0..<NumColumns {
      var row = 0
      while row < NumRows-2 {
        if let bobbleHead = bobbleHeads[column, row] {
          let matchType = bobbleHead.bobbleHeadType

          if bobbleHeads[column, row + 1]?.bobbleHeadType == matchType &&
            bobbleHeads[column, row + 2]?.bobbleHeadType == matchType {
            let chain = Chain(chainType: .Vertical)
            repeat {
              chain.addBobbleHead(bobbleHeads[column, row]!)
              row += 1
            } while row < NumRows && bobbleHeads[column, row]?.bobbleHeadType == matchType

            set.insert(chain)
            continue
          }
        }    
        row += 1
      }
    }
    return set
  }

  private func hasChainAtColumn(column: Int, row: Int) -> Bool {
    let bobbleHeadType = bobbleHeads[column, row]!.bobbleHeadType

    // Horizontal chain check
    var horzLength = 1

    // Left
    var i = column - 1
    while i >= 0 && bobbleHeads[i, row]?.bobbleHeadType == bobbleHeadType {
      i -= 1
      horzLength += 1
    }

    // Right
    i = column + 1
    while i < NumColumns && bobbleHeads[i, row]?.bobbleHeadType == bobbleHeadType {
      i += 1
      horzLength += 1
    }
    if horzLength >= 3 { return true }

    // Vertical chain check
    var vertLength = 1

    // Down
    i = row - 1
    while i >= 0 && bobbleHeads[column, i]?.bobbleHeadType == bobbleHeadType {
      i -= 1
      vertLength += 1
    }

    // Up
    i = row + 1
    while i < NumRows && bobbleHeads[column, i]?.bobbleHeadType == bobbleHeadType {
      i += 1
      vertLength += 1
    }
    if vertLength >= 3 { return true }

    // Check for L shapes
    if horzLength == 2 || vertLength == 2 {
//      if horzLength == 2 {
//        print("horzLength == 2")
//        let possibleLs = [[row - 1, column], [row - 1, column + 1], [row + 1, column], [row + 1, column + 1]]
//        print("\tpossibleLs: \(possibleLs)")
//        let validLs = possibleLs.filter { pair in
//          let r = pair[0]
//          let c = pair[1]
//
//          return r >= 0 && c >= 0 && r < NumRows && c < NumColumns
//        }
//        print("\t\tvalidLs: \(validLs)")
//
//        let foundLs = validLs.filter { pair in
//          bobbleHeads[pair[1], pair[0]]?.bobbleHeadType == bobbleHeadType
//        }
//
//        print("\t\t\tfoundLs: \(foundLs)")
//
//        if !foundLs.isEmpty { return true }
//      }
//
//      if vertLength == 2 {
//        return false
//      }
      return false // TODO REPLACE
    } else {
      return false
    }
  }

  private func removeBobbleHeads(chains: Set<Chain>) {
    for chain in chains {
      for bobbleHead in chain.bobbleHeads {
        bobbleHeads[bobbleHead.column, bobbleHead.row] = nil
      }
    }
  }

  func fillHoles() -> [[BobbleHead]] {
    var columns = [[BobbleHead]]()
    // 1
    for column in 0..<NumColumns {
      var array = [BobbleHead]()
      for row in 0..<NumRows {
        // 2
        if tiles[column, row] != nil && bobbleHeads[column, row] == nil {
          // 3
          for lookup in (row + 1)..<NumRows {
            if let bobbleHead = bobbleHeads[column, lookup] {
              // 4
              bobbleHeads[column, lookup] = nil
              bobbleHeads[column, row] = bobbleHead
              bobbleHead.row = row
              // 5
              array.append(bobbleHead)
              // 6
              break
            }
          }
        }
      }
      // 7
      if !array.isEmpty {
        columns.append(array)
      }
    }
    return columns
  }

  func topUpBobbleHeads() -> [[BobbleHead]] {
    var columns = [[BobbleHead]]()
    var bobbleHeadType: BobbleHeadType = .Unknown

    for column in 0..<NumColumns {
      var array = [BobbleHead]()

      // 1
      var row = NumRows - 1
      while row >= 0 && bobbleHeads[column, row] == nil {
        // 2
        if tiles[column, row] != nil {
          // 3
          var newBobbleHeadType: BobbleHeadType
          repeat {
            newBobbleHeadType = picker.pickRandom()
          } while newBobbleHeadType == bobbleHeadType
          bobbleHeadType = newBobbleHeadType
          // 4
          let bobbleHead = BobbleHead(column: column, row: row, bobbleHeadType: bobbleHeadType)
          bobbleHeads[column, row] = bobbleHead
          array.append(bobbleHead)
        }

        row -= 1
      }
      // 5
      if !array.isEmpty {
        columns.append(array)
      }
    }
    return columns
  }

  func tileAtColumn(column: Int, row: Int) -> Tile? {
    assert(column >= 0 && column < NumColumns)
    assert(row >= 0 && row < NumRows)
    return tiles[column, row]
  }

  private func createInitialBobbleHeads() -> Set<BobbleHead> {
    var set = Set<BobbleHead>()

    // 1
    for row in 0..<NumRows {
      for column in 0..<NumColumns {
        if tiles[column, row] != nil {
          // 2
          var bobbleHeadType: BobbleHeadType
          repeat {
            bobbleHeadType = picker.pickRandom()
          } while (column >= 2 &&
            bobbleHeads[column - 1, row]?.bobbleHeadType == bobbleHeadType &&
            bobbleHeads[column - 2, row]?.bobbleHeadType == bobbleHeadType)
            || (row >= 2 &&
              bobbleHeads[column, row - 1]?.bobbleHeadType == bobbleHeadType &&
              bobbleHeads[column, row - 2]?.bobbleHeadType == bobbleHeadType)

          // 3
          let bobbleHead = BobbleHead(column: column, row: row, bobbleHeadType: bobbleHeadType)
          bobbleHeads[column, row] = bobbleHead

          // 4
          set.insert(bobbleHead)
        }
      }
    }
    return set
  }
}