//
//  OrientationKit.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 7/8/23.
//

/*
 These extension contains functionality used to keep track of the device's orientation and react accordingly.
 For example in collection view, these functions are used to configure the grid layout.
 In editor view they are used to display the correct image and cropping information so that each meme can present different vertical and horizontal versions.
 Could potentially use some of this functionality in other apps.
 */

import Foundation
import UIKit

extension UIViewController {
    
    enum Layout {
        case vertical, horizontal
    }
    
    /*
     Note to self: Using struct here because extensions are not allowed to contain stored properties.
     Using static var so the layoutStyle can be accessed using OKit.layoutStyle without creating an OKit instance.
     */
    struct OKit {
        static var layoutStyle: Layout = .vertical
        // default value is needed in case the device is face up when the app is started
    }
    
    
    /*
     Call this function whenever the device orientation changes, in order to re-set the layout style to
     vertical or horizontal as appropriate.
     */
    public func resetLayoutStyle() {
        
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .portrait, .portraitUpsideDown:
            OKit.layoutStyle = .vertical
        case .landscapeLeft, .landscapeRight:
            OKit.layoutStyle = .horizontal
        default:
            debugPrint("no change")
            // layout style will not change unless the device is turned to a vertical or horizontal position.
        }
    }
    
    
    /*
     dimensions Function returns short and long dimensions.
     For some reason UIKit appears to give a frame dimensions that are based on the initial orientation of the view,
     but do not change places when the orientation changes.
     That means when getting the height and width of a frame, you can't know which is the longer dimension.
     (I may be missing something but that's what I've observed.)
     This function accepts a rectangle, returning a .short and .long dimension, which can then be used to properly calculate layouts and cropping frames.
     */
    
    public func dimensions(_ frame:CGRect) -> (short:CGFloat, long:CGFloat) {
        
        var short = frame.width
        var long = frame.height
        
        if short > long {
            short = frame.height
            long = frame.width
        }
        
        return (short,long)
    }
    
}
