//
//  Cookie.swift
//  CookieCrunch
//
//  Created by Stephen Schwahn on 12/22/15.
//  Copyright © 2015 Stephen Schwahn. All rights reserved.
//

import SpriteKit

enum CookieType: Int, CustomStringConvertible {
    case Unknown = 0, Croissant, Cupcake, Danish, Donut, Macaroon, SugarCookie
    
    var spriteName : String {
        let spriteNames = [
            "Croissant",
            "Cupcake",
            "Danish",
            "Donut",
            "Macaroon",
            "SugarCookie"]
        
        return spriteNames[rawValue-1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func random() -> CookieType {
        return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    
    var description: String {
        return spriteName
    }
}

class Cookie : CustomStringConvertible, Hashable {
    var row: Int
    var col: Int
    let cookieType: CookieType
    var sprite: SKSpriteNode?
    
    var description: String {
        return "type:\(cookieType) square:(\(col),\(row))"
    }
    
    var hashValue: Int {
        return row*10 + col
    }
    
    init(column: Int, row: Int, cookieType: CookieType) {
        self.col = column
        self.row = row
        self.cookieType = cookieType
    }
}

func ==(lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.col == rhs.col && lhs.row == rhs.row
}