//
//  DetailViewController.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 7/6/23.
//

import Foundation
import UIKit


class DetailViewController:UIViewController {
    
    
    // MARK: Properties
    
    var myMeme = Meme()
    
    
    // MARK: IBOutlets
    
    @IBOutlet weak var memeView:UIImageView!
    
    
   
    // MARK: Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !myMeme.isSharable {
/*            let editor = storyboard?.instantiateViewController(withIdentifier: "EditorView") as! MemeEditorViewController
            editor.myMeme = myMeme
            editor.modalPresentationStyle = .fullScreen
            navigationController?.present(editor, animated: true)
*/
            debugPrint("I'm getting ready to call a segue.")
            performSegue(withIdentifier: "EditorView", sender: self)
            
        } else {
            memeView.image = myMeme.memedImage
        }
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        debugPrint("I'm in the prepare for segue function.")
        if segue.identifier == "EditView" {
            let editor = segue.destination as! MemeEditorViewController
            editor.myMeme = myMeme
        }
    }
        
    // MARK: IBActions
        
    
    @IBAction func edit() {
        let editor = storyboard?.instantiateViewController(withIdentifier: "EditorView") as! MemeEditorViewController
        editor.myMeme = myMeme
        editor.modalPresentationStyle = .fullScreen
        present(editor, animated: false)
    }
    
    @IBAction func share() {
        
    }
    
}
