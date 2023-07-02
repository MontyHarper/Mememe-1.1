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

