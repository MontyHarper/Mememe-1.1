//
//  Model.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 6/12/23.
//

import Foundation
import UIKit


// For the storage of memes, with all their parts

struct Meme {
    
    var topText: String = "TOP TEXT"
    var bottomText: String = "BOTTOM TEXT"
    var image: UIImage?
    var croppedImageLandscape: UIImage?
    var croppedImagePortrait: UIImage?
    var cropFrameLandscape: CGRect?
    var cropFramePortrait: CGRect?
    var memedImage: UIImage?
    
}



/*
 Disused Function
 I wrote this function to determine whether an optional string appears to be empty.
 My initial thought was to disallow an empty top or bottom text field for my memes.
 However, I decided I like having the ability to enter blank spaces to opt out of using either text field.
 I'll just leave this here in case I change my mind again.

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

*/


