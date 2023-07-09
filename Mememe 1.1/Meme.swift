//
//  Model.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 6/12/23.
//

import Foundation
import UIKit


/*
 My memes each contain two different cropping options; one for vertical and one for horizontal,
 effectively allowing each meme to possibly contain two different presentations.
 I may come back to this idea and implement it fully with the ability to save two different images as well;
 At this time the image must be the same in both presentations.
 */
struct Meme {
    
    static let topPlaceholder = "TOP TEXT" // Use to set the initial text shown in an empty meme.
    static let bottomPlaceholder = "BOTTOM TEXT" // Use to set the initial text shown in an empty meme.
    
    var topText: String = topPlaceholder
    var bottomText: String = bottomPlaceholder
    var image: UIImage?
    var croppedImageLandscape: UIImage?
    var croppedImagePortrait: UIImage?
    var cropFrameLandscape: CGRect?
    var cropFramePortrait: CGRect?
    var memedImage: UIImage?
    var id: Int? // Id numbers are set to a meme's index number in the array for convenience in saving and deleting
    
    
    // Communicates whether a meme instance is ready to be shared (for activating the share button).
    var isSharable: Bool {
        if topText != Meme.topPlaceholder && bottomText != Meme.bottomPlaceholder && image != nil {
            return true
        } else {
            return false
        }
    }
    
    // Communicates whether a meme instance is brand new and empty (if so, open the editor).
    var isEmpty: Bool {
        if topText == Meme.topPlaceholder && bottomText == Meme.bottomPlaceholder && image == nil {
            return true
        } else {
            return false
        }
    }
}

