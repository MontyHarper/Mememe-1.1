//
//  SavedMemesCollectionViewController.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 7/3/23.
//
//  This VC displays saved memes in a grid layout.
//

import Foundation
import UIKit

class SavedMemesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {


    // MARK: Properties
    
    // Loading in all the memes to display.
    var memes: [Meme]! {
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        return appDelegate.memes
    }
    
    // These values are used to configure the grid for horizonal and vertical layouts. Initial values are arbitrary.
    var space:CGFloat = 20.0
    var margin:CGFloat = 20.0
    var xDimension:CGFloat = 20.0
    var yDimension:CGFloat = 20.0
    


    // MARK: Outlets
    
    // UIKit uses a flow layout object to determine spacing for the grid.
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    // MARK: Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This function sets up the spacing for the grid.
        setFlowLayout()
        
        /*
         If no memes exist yet to be displayed, this opens the editor to create one.
         Note that project specifications require the app to open to a saved memes view.
         Technically, it does, but you don't see it on screen.
         That would make better sense if the app stored persistant data.
         As is the app would always open to basically a blank screen.
         I prefer to send the user straight to the editor to make a first meme.
         As soon as I can update the app to save persistant data, it will open to the saved memes page on subsequent uses.
         If this implementation is a problem, I can just comment out the following if statement.
         */
        if memes.count == 0 {
            let editor = storyboard?.instantiateViewController(withIdentifier: "EditorView") as! MemeEditorViewController
            editor.hidesBottomBarWhenPushed = true
            navigationController?.setNavigationBarHidden(true, animated: true)
            navigationController?.pushViewController(editor, animated: true)
        }
    }
        
    // Necessary to display changes after returning from the editor.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    
    
    // MARK: Collection View Controller Functions
    
    // Detects when the device changes orientation and adjusts accordingly.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setFlowLayout()
        collectionView.reloadData()
    }
    
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
    
    // This function sets up the spacing for the grid.
    func setFlowLayout() {
        
        // Making sure we know the current orientation of the device: .vertical or .horizontal
        resetLayoutStyle()
        
        // Returns a long and a short dimension for the view.
        let size = dimensions(view.frame)

        switch OKit.layoutStyle { // Spacing is dependent on horizontal vs. vertical orientation.
        case .vertical:
            space = 10.0 // Adjust space between cells
            margin = 10.0 // Adjust space at sides of the grid
            xDimension = (size.short - (2 * space + 2 * margin)) / 3 // These calculate the size of a cell
            yDimension = (size.long - (5 * space)) / 4
        case .horizontal:
            space = 10.0
            margin = 50.0
            xDimension = (size.long - (3 * space + 2 * margin)) / 4
            yDimension = (size.short - (3 * space)) / 2
        }
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: xDimension, height: yDimension)
        flowLayout.sectionInset = UIEdgeInsets(top: space, left: margin, bottom: space, right: margin)
    }
}
