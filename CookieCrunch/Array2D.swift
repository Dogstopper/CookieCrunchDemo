//
//  Array2D.swift
//  CookieCrunch
//
//  Created by Stephen Schwahn on 12/22/15.
//  Copyright © 2015 Stephen Schwahn. All rights reserved.
//

struct Array2D<T> {
    let rows : Int
    let cols : Int
    private var array : Array<T?>
    
    init(cols: Int, rows: Int) {
        self.rows = rows
        self.cols = cols
        array = Array<T?>(count: rows*cols, repeatedValue: nil)
    }
    
    subscript(col: Int, row: Int) -> T? {
        get {
            return array[row*cols + col]
        }
        set {
            array[row*cols + col] = newValue
        }
    }
}