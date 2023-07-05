//
//  SavedMemesCollectionViewController.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 7/3/23.
//

import Foundation
import UIKit

class SavedMemesCollectionViewController: UICollectionViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    // MARK: Properties
    
    var memes: [Meme]! {
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        return appDelegate.memes
    }
    
    // MARK: Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // needs adjusting for height in landscape; use view.frame.size.height
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0

        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        debugPrint("View did load. These are the memes: \(memes as Any)")
    }
    

    
    
    // MARK: Collection View Controller Functions
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        debugPrint(memes.count)
        return memes.count

    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let meme = memes[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemesCollectionViewCell", for: indexPath) as! MemesCollectionViewCell
        cell.imageView?.image = meme.memedImage
        return cell
    }
    
}
