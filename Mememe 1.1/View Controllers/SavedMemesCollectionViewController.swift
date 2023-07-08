//
//  SavedMemesCollectionViewController.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 7/3/23.
//

import Foundation
import UIKit

class SavedMemesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    // MARK: Properties
    
    var memes: [Meme]! {
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        return appDelegate.memes
    }
    
    let device = UIDevice.current
    var orientation: UIDeviceOrientation = .portrait
    var space:CGFloat = 20.0
    var margin:CGFloat = 20.0
    var xDimension:CGFloat = 20.0
    var yDimension:CGFloat = 20.0
    


    // MARK: Outlets
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    // MARK: Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setFlowLayout()
        
        // If no memes exist yet, pass an empty meme to the detail view, which will get passed to the editor.
        if memes.count == 0 {
            
            let meme = Meme()
            let detailView = storyboard?.instantiateViewController(withIdentifier: "EditorView") as! MemeEditorViewController
            detailView.myMeme = meme
            detailView.hidesBottomBarWhenPushed = true
            navigationController?.setNavigationBarHidden(true, animated: true)
            navigationController?.pushViewController(detailView, animated: true)
            
        }
    }
        
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setFlowLayout()
        collectionView.reloadData()
        debugPrint("View Will Transition")
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

    override func collectionView(_ collectionView:UICollectionView, didSelectItemAt indexPath: IndexPath) {
 
        let detailView = storyboard?.instantiateViewController(withIdentifier: "DetailView") as! DetailViewController
        let selectedMeme = memes[indexPath.row]
        detailView.myMeme = selectedMeme
        detailView.hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(detailView, animated: true)
    }
    
    
    
    func setFlowLayout() {
        
        orientation = device.orientation
        
        var width = view.frame.width
        var length = view.frame.height
        
        if width > length {
            let temp = length
            length = width
            width = temp
        }

        
        switch orientation {
        case .portrait, .portraitUpsideDown:
            space = 10.0
            margin = 10.0
            xDimension = (width - (2 * space + 2 * margin)) / 3
            yDimension = (length - (5 * space)) / 4
        case .landscapeLeft, .landscapeRight:
            space = 10.0
            margin = 50.0
            xDimension = (length - (3 * space + 2 * margin)) / 4
            yDimension = (width - (3 * space)) / 2
        default:
            debugPrint("unknown orientation")
        }
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: xDimension, height: yDimension)
        flowLayout.sectionInset = UIEdgeInsets(top: space, left: margin, bottom: space, right: margin)
    }
}
