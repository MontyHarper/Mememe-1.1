//
//  DetailViewController.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 7/6/23.
//
//  Detail view shows an image of the meme with options to Edit, Delete, or Share (if ready).


import Foundation
import UIKit

class DetailViewController:UIViewController {
    
    
    // MARK: Properties
    
    // This is the meme to be displayed, edited, deleted, or shared.
    var myMeme = Meme()
    
    
    
    // MARK: IBOutlets
    
    @IBOutlet weak var memeView: UIImageView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    
    
    // MARK: Lifecycle Functions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // display the selected meme
        memeView.image = myMeme.memedImage
        shareButton.isEnabled = myMeme.isSharable
    }
    
    
    
    // MARK: IBActions
    
    @IBAction func edit() {
        let editor = storyboard?.instantiateViewController(withIdentifier: "EditorView") as! MemeEditorViewController
        editor.myMeme = myMeme
        editor.hidesBottomBarWhenPushed = true
        editor.delegate = self // Allows the editor to send the updated meme back here to the detail view.
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.pushViewController(editor, animated: true)
    }
    
    @IBAction func share() {
        
        let activityController = UIActivityViewController(activityItems: [myMeme.memedImage!], applicationActivities: nil)
        
        /*
         completionWithItemsHandler is an enclosure attatched to the activity view controller.
         The view controller will execute this code when the user has completed or dismissed the activity.
         In version 1.0 this is where the meme was saved.
         I have separated that functionality for version 2.0.
         Memes are saved in the editor so they can be saved "In Progress."
         They can be shared from here (the detail view), but only once they have been completed.
         All this really does now is close the activity view controller.
         */
        activityController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            if let error = activityError {
                debugPrint(error)
            }
            if !completed {
                debugPrint("The sharing activity was cancelled.")
            }
            
            // Magic courtesy of UdacityGPT, for popping back to Detail view.
            if let navigationController = self.navigationController,
               let detailViewController = navigationController.viewControllers.first(where: { $0 is DetailViewController }) {
                navigationController.popToViewController(detailViewController, animated: true)
            }
        }
        
        if let popOver = activityController.popoverPresentationController {
            popOver.sourceView = self.view
        }
        
        present(activityController, animated: true, completion: nil)
    }
    
    @IBAction func delete() {
        
        // This allows access to the meme array
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        /*
         myMeme.id is the index number for that meme in the array.
         Use it to remove the meme from the array.
         Then re-set all the id numbers, since some of the meme indexes will have changed.
         */
        if let id = myMeme.id {
            
            appDelegate.memes.remove(at: id)
            let last = appDelegate.memes.count - 1
            
            // adjust id numbers so they match indexes
            if last >= 0 {
                for i in 0...last {
                    appDelegate.memes[i].id = i
                }
            }
            
        } else {
            debugPrint("missing meme id") // This should never happen.
        }
        
        // Go back to the saved memes view.
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func myUnwindAction(unwindSegue: UIStoryboardSegue) {
    }
    
    // MARK: Advocate Functions
    
    // This is called from the editor before returning us back to the detail view in order to show updates to the meme.
    func updateMeme (_ newMeme:Meme) {
        myMeme = newMeme
        memeView.image = myMeme.memedImage
        shareButton.isEnabled = myMeme.isSharable
    }
    
    
    
}
