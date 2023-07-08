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
    @IBOutlet weak var shareButton:UIBarButtonItem!
   
    // MARK: Lifecycle Functions
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        memeView.image = myMeme.memedImage
        }
    
        
    // MARK: IBActions
        
    
    @IBAction func edit() {
        let editor = storyboard?.instantiateViewController(withIdentifier: "EditorView") as! MemeEditorViewController
        editor.myMeme = myMeme
        editor.hidesBottomBarWhenPushed = true
        editor.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.pushViewController(editor, animated: true)
    }
    
    @IBAction func share() {
        print("Sharing meme")
    }
    
    @IBAction func delete() {
        print("deleting meme")
    }
    
    func updateMeme (_ newMeme:Meme) {
        myMeme = newMeme
        memeView.image = myMeme.memedImage
    }
    
}
