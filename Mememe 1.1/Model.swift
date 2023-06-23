//
//  Model.swift
//  Mememe 1.0
//
//  Created by Monty Harper on 6/12/23.
//

import Foundation
import UIKit

// I wasn't completely sure where to put this stuff, but I figure it does not belong in the view controller.


// For the storage of memes, with all their parts

struct Meme {
    
    var topText: String = "TOP TEXT"
    var bottomText: String = "BOTTOM TEXT"
    var image: UIImage?
    var croppedImage: UIImage?
    var cropFrame: CGRect?
    var memedImage: UIImage?
    
}



// This func determines whether an optional string is either nil or consists only of spaces and so appears to be empty
// Currently the app doesn't use this for anything.

func isEmpty(_ text:String?) -> Bool {
  
    if let str = text {
        for char in str {
            if char != " " {
                return false
            }
        }
    }
    return true
}

