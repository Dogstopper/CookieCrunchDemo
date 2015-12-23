//
//  Extensions.swift
//  CookieCrunch
//
//  Created by Stephen Schwahn on 12/22/15.
//  Copyright © 2015 Stephen Schwahn. All rights reserved.
//

import Foundation

extension Dictionary {
    static func loadJSONFromBundle(filename: String) -> Dictionary<String, AnyObject>? {
        if let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json") {
            do {
                let data : NSData? = try NSData(contentsOfFile: path, options: NSDataReadingOptions())
                if let data = data {
                    let dictionary: AnyObject? = try NSJSONSerialization.JSONObjectWithData(data,
                        options: NSJSONReadingOptions())
                    if let dictionary = dictionary as? Dictionary<String, AnyObject> {
                        return dictionary
                    } else {
                        print("Level file '\(filename)' is not valid JSON")
                        return nil
                    }
                }
                else {
                    print("Could not load level file: \(filename)")
                    return nil
                }
                
            } catch {
                print("Level file '\(filename)' is not valid JSON: \(error)")
                return nil
            }
        } else {
            print("Could not find level file: \(filename)")
            return nil
        }
    }
}