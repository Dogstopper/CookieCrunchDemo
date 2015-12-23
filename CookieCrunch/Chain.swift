//
//  Chain.swift
//  CookieCrunch
//
//  Created by Stephen Schwahn on 12/22/15.
//  Copyright © 2015 Stephen Schwahn. All rights reserved.
//

class Chain: Hashable, CustomStringConvertible {
    var cookies = [Cookie]()
    var score = 0
    
    enum ChainType: CustomStringConvertible {
        case Horizontal
        case Vertical
        case LShaped
        
        var description : String {
            switch self {
            case .Horizontal: return "Horizontal"
            case .Vertical: return "Vertical"
            case .LShaped: return "L-Shaped"
            }
        }
    }
    
    var chainType : ChainType
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func addCookie(cookie: Cookie) {
        cookies.append(cookie)
    }
    
    func firstCookie() -> Cookie {
        return cookies[0]
    }
    
    func lastCookie() -> Cookie {
        return cookies[cookies.count - 1]
    }
    
    var length: Int {
        return cookies.count
    }
    
    var description: String {
        return "type:\(chainType) cookies:\(cookies)"
    }
    
    var hashValue: Int {
        return cookies.reduce(0) { $0.hashValue ^ $1.hashValue }
    }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
    return lhs.cookies == rhs.cookies
}