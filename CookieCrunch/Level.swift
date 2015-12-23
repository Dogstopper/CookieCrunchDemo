//
//  Level.swift
//  CookieCrunch
//
//  Created by Stephen Schwahn on 12/22/15.
//  Copyright © 2015 Stephen Schwahn. All rights reserved.
//

import Foundation

let NumRows = 9
let NumCols = 9

class Level{
    
    // MARK: - Instance variables
    
    private var cookies = Array2D<Cookie>(cols: NumCols, rows: NumRows)
    private var tiles = Array2D<Tile>(cols: NumCols, rows: NumRows)
    private var possibleSwaps = Set<Swap>()
    
    var targetScore = 0
    var maximumMoves = 0
    
    //MARK: - Initialization
    
    init(filename: String) {
        // Load a level from one of the Bundled JSON files
        if let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename) {
            
            // The Disctionary contains an array named "titles, and this array contains
            // one element for each row of the level. Each element is also an array 
            // describing the columns for that particular row. If a column value is 1,
            // it means that (row, col) is a valid "slot"
            if let tilesArray : AnyObject = dictionary["tiles"] {
                for (row, rowArray) in (tilesArray as! [[Int]]).enumerate() {
                    
                    // In SprikeKit, the (0,0) is in the bottom-left, so we need to read
                    // this file in reverse (as it starts in the top-left
                    let tileRow = NumRows - row - 1
                    for (column, value) in rowArray.enumerate() {
                        if value == 1 {
                            tiles[column, tileRow] = Tile()
                        }
                    }
                }
                targetScore = dictionary["targetScore"] as! Int
                maximumMoves = dictionary["moves"] as! Int
            }
        }
    }
    
    // Fills up the level with cookie objects. The level is guaranteed to be free
    // of matches at this point.
    // This is called at the start of any new game.
    func shuffle() -> Set<Cookie> {
        var set: Set<Cookie>
        repeat {
            
            // Fills the screen with brand new cookie objects
            set = createInitialCookies()
            
            // At the start of each turn, we detect which tiles are actualy swappable
            // and if the player tries to swap tile that are NOT in this set, then it fails.
            detectPossibleSwaps()
            //print("possible swaps: \(possibleSwaps)")
        }
        while possibleSwaps.count == 0 // Try until there are valid swaps.
        
        return set
    }
    
    private func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        
        for row in 0..<NumRows {
            for col in 0..<NumCols {
                if tiles[col, row] != nil {
                    var cookieType : CookieType
                    repeat {
                        cookieType = CookieType.random()
                    }
                        while (col >= 2 &&
                            cookies[col - 1, row]?.cookieType == cookieType &&
                            cookies[col - 2, row]?.cookieType == cookieType)
                            || (row >= 2 &&
                                cookies[col, row - 1]?.cookieType == cookieType &&
                                cookies[col, row - 2]?.cookieType == cookieType)
                    
                    let cookie = Cookie(column: col, row: row, cookieType: cookieType)
                    cookies[col, row] = cookie
                    
                    set.insert(cookie)
                }
            }
        }
        return set;
    }
    
    // MARK: - Query the level
    
    func cookieAtColumn(col: Int, row: Int) -> Cookie? {
        assert(col >= 0 && col < NumCols)
        assert(row >= 0 && row < NumRows)
        return cookies[col, row]
    }
    
    func tileAtColumn(col: Int, row: Int) -> Tile? {
        assert(col >= 0 && col < NumCols)
        assert(row >= 0 && row < NumRows)
        return tiles[col, row]
    }
    
    func isPossibleSwap(swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    // MARK: - Swapping
    
    func performSwap(swap: Swap) {
        let colA = swap.cookieA.col
        let rowA = swap.cookieA.row
        let colB = swap.cookieB.col
        let rowB = swap.cookieB.row
        
        cookies[colA, rowA] = swap.cookieB
        swap.cookieB.col = colA
        swap.cookieB.row = rowA
        
        cookies[colB, rowB] = swap.cookieA
        swap.cookieA.col = colB
        swap.cookieA.row = rowB
    }
    
    // MARK: - Detecting Swaps
    
    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumCols {
                if let cookie = cookies[column, row] {
                    
                    // Is it possible to swap this cookie with the one on the right?
                    if column < NumCols - 1 {
                        
                        // Have a cookie at this spot? If there is no tile, there's no cookie
                        if let other = cookies[column + 1, row] {
                            // Swap them.
                            cookies[column, row] = other
                            cookies[column + 1, row] = cookie
                            
                            // Is either cookie a member of a chain?
                            if hasChainAtColumn(column + 1, row: row) ||
                               hasChainAtColumn(column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column+1, row] = other
                        }
                    }
                    // Is it possible to swap this cookie with the one on the top?
                    if row < NumRows - 1 {
                        // Have a cookie at this spot? If there is no tile, there's no cookie
                        if let other = cookies[column, row + 1] {
                            // Swap them.
                            cookies[column, row] = other
                            cookies[column, row + 1] = cookie
                            
                            // Is either cookie a member of a chain?
                            if hasChainAtColumn(column, row: row + 1) ||
                               hasChainAtColumn(column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column, row + 1] = other
                        }
                    }
                }
            }
        }
        possibleSwaps = set
    }
    
    private func hasChainAtColumn(column: Int, row: Int) -> Bool {
        let cookieType = cookies[column, row]!.cookieType
        
        var horzLength = 1
        for var i = column - 1; i >= 0 && cookies[i, row]?.cookieType == cookieType; --i, ++horzLength { }
        for var i = column + 1; i < NumCols && cookies[i, row]?.cookieType == cookieType; ++i, ++horzLength { }
        if horzLength >= 3 { return true }
        
        var vertLength = 1
        for var i = row - 1; i >= 0 && cookies[column, i]?.cookieType == cookieType; --i, ++vertLength { }
        for var i = row + 1; i < NumRows && cookies[column, i]?.cookieType == cookieType; ++i, ++vertLength { }
        return vertLength >= 3
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        // For each row....
        for row in 0..<NumRows {
            
            // Loop through the columns from index 0 to NumCols - 2
            for var column = 0; column < NumRows - 2 ; {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    // Check if the next two elements are the same type of cookie
                    if cookies[column + 1, row]?.cookieType == matchType &&
                        cookies[column + 2, row]?.cookieType == matchType {
                            
                            // Generate a chain of 3+ cookies horizontally
                            let chain = Chain(chainType: .Horizontal)
                            repeat {
                                chain.addCookie(cookies[column, row]!)
                                ++column
                            }
                                while column < NumCols && cookies[column, row]?.cookieType == matchType
                            
                            // Add the chain to the set
                            set.insert(chain)
                            continue
                    }
                }
                ++column
            }
        }
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        // For each column...
        for column in 0..<NumCols {
            
            // Loop through the rows from index 0 to NumCols - 2
            for var row = 0; row < NumRows - 2; {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    // Check if the next two elements are the same type of cookie
                    if cookies[column, row + 1]?.cookieType == matchType &&
                        cookies[column, row + 2]?.cookieType == matchType {
                            
                            // Generate a chain of 3+ cookies vertically
                            let chain = Chain(chainType: .Vertical)
                            repeat {
                                chain.addCookie(cookies[column, row]!)
                                ++row
                            }
                                while row < NumRows && cookies[column, row]?.cookieType == matchType
                            
                            set.insert(chain)
                            continue
                    }
                }
                ++row
            }
        }
        return set
    }
    
    // MARK: - Scoring
    
    private var comboMultiplier = 0
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
    
    private func calculateScores(chains: Set<Chain>) {
        // 3-chain is 60 points, 4-chain is 120, 5-chain is 180, etc.
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            ++comboMultiplier
        }
    }

    // MARK: - Matches
    
    func removeMatches() -> Set<Chain> {
        // Get all chains
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        // TODO: Implement L-shaped chains
        
        // Remove cookies of all the chains
        removeCookies(horizontalChains)
        removeCookies(verticalChains)
        
        // Calculate scores
        calculateScores(horizontalChains)
        calculateScores(verticalChains)
        
        // Make a total set of all chains
        return horizontalChains.union(verticalChains)
    }
    
    func fillHoles() -> [[Cookie]] {
        var columns = [[Cookie]]()
        
        for column in 0..<NumCols {
            var array = [Cookie]()
            for row in 0..<NumRows {
                // If we hit a spot with no cookie, but SHOULD have one...
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    
                    // Iterate upwards and swap with the next available cookie
                    for lookup in (row + 1)..<NumRows {
                        if let cookie = cookies[column, lookup] {
                            cookies[column, lookup] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            
                            array.append(cookie)
                            break
                        }
                    }
                }
                // This repetition will fix the now-adjusted cookies
            }
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpCookies() -> [[Cookie]] {
        var columns = [[Cookie]]()
        var cookieType : CookieType = .Unknown
        
        // For each column
        for column in 0..<NumCols {
            var array = [Cookie]()
            
            // Iterate from the top down ehile there are empty slots
            for var row = NumRows - 1; row >= 0 && cookies[column, row] == nil; --row {
                // If there is actually supposed to be a cookie at that spot
                if tiles[column, row] != nil {
                    
                    // Create cookies until it is not the previous cookie
                    // We don't want too many "free" chains
                    var newCookieType : CookieType
                    repeat {
                        newCookieType = CookieType.random()
                    } while newCookieType == cookieType
                    cookieType = newCookieType
                    
                    // Create the new cookie and add it to the column's array
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    array.append(cookie)
                }
            }
            // If there are no fixes, don't add it
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    private func removeCookies(chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.col, cookie.row] = nil
            }
        }
    }
}