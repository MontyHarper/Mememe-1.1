//
//  SavedMemesTableViewController.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 7/3/23.
//
//  Table VC - displays a list of memes with an image plus text from the top and bottom of the meme.
//

import Foundation
import UIKit


class SavedMemesTableViewController: UITableViewController {
    
    // MARK: Properties
    
    // Loading in the memes to be listed.
    var memes: [Meme]! {
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        return appDelegate.memes
    }
    
    
    // MARK: Lifecycle Functions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Needed to show changes when returning from the editor.
        tableView.reloadData()
        
        // Checks device orientation and adjusts row heights accordingly.
        resetTableRowHeight()
    }
    
    
    // MARK: Table View Controller Functions
    
    // Reset table row heights if the device changes orientation.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resetTableRowHeight()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let meme = memes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "memeTableCell")!
        cell.textLabel?.text = meme.topText + " " + meme.bottomText
        cell.imageView?.image = meme.memedImage
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailView = storyboard?.instantiateViewController(withIdentifier: "DetailView") as! DetailViewController
        let selectedMeme = memes[indexPath.row]
        detailView.myMeme = selectedMeme
        detailView.hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(detailView, animated: true)
    }
    
    func resetTableRowHeight() {
        
        // Checks current device orientation
        resetLayoutStyle()

        // Gets the .short and .long dimensions of the table view.
        let size = dimensions(tableView.frame)
        
        // Sets row height appropriately according to .vertical or .horizontal orientation.
        switch OKit.layoutStyle {
        case .vertical:
            tableView.rowHeight = size.long / 8 // Divide by approximate number of rows desired.
        case .horizontal:
            tableView.rowHeight = size.short / 4
        }
    }
    
}
