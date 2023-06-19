//
//  ViewController.swift
//  Mememe 1.0
//
//  Created by Monty Harper on 6/3/23.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate {
 
    
// MARK: IBOutlets
    
    @IBOutlet weak var myPhoto: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var memeView: UIView!


    
   
// MARK: Properties
    
    // Default image to use for testing purposes
    let testImage: UIImage = UIImage(named:"Sinclair-ZX81")!
    
    // Dictionary of text attributes for the meme top and bottom text
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        .strokeColor: UIColor.black,
        .foregroundColor: UIColor.white,
        .font: UIFont(name: "Impact", size: 40)!,
        .strokeWidth:  -4.0,
    ]
    
    
    
// MARK: Lifecycle Methods
    
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        setupText(topText,bottomText)
        toggleShareButton()
    }
    
    // called from viewWillAppear to set up properties of the two text fields.
    func setupText(_ textFields:UITextField...) {
        for text in textFields {
            text.defaultTextAttributes = memeTextAttributes
            text.textAlignment = .center
            text.autocapitalizationType = .allCharacters
            // placeholder text is set in storyboard, stored here & used to replace an empty text field
            text.placeholder = text.text
        }
        
    }
    
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topText.delegate = self
        bottomText.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
           view.addGestureRecognizer(tapGesture)
    }
    
    
    
//MARK: IBActions

    @IBAction func selectPhoto(_ sender: UIButton) {
       
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        let cropRect = memeView.frame
      //  pickerController.setCropRect(memeView.frame) - apparently this is deprecated
        
        // choose camera or photo album depending on which button was pressed
        switch sender.tag {
        case 1:
            pickerController.sourceType = .camera
        default:
            pickerController.sourceType = .photoLibrary
        }
       
        present(pickerController, animated: true, completion: nil)
    }

    
    @IBAction func share(_ sender: Any) {
      let memedImage = generateMemedImage()
      let activityController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
      /* completionWithItemsHandler is an enclosure attatched to the activity view controller, to be defined here.
       The view controller will execute this code when the user has completed or dismissed the activity. */
        
        activityController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            if completed {
                /* Save the meme if the activity was completed.
                 I'm not sure why we're saving the meme to begin with or what that even means.
                 I can assign the meme to a variable but then what?
                 (We haven't covered persistant data yet.)
                 I assume this will come into play in Mememe 2.0. */
                
                let myMeme = Meme(topText: self.topText.text!, bottomText: self.bottomText.text!, image: self.myPhoto.image!, memedImage: memedImage)
                
            } else {
                // The sharing action was canceled, handle the cancellation if needed
                // I don't believe we have anything to do here
            }

            if let error = activityError {
                // Handle the error
                print(error)
            }
            
            self.dismiss(animated: true, completion: nil)
        }
        
        // End of completion handler. Continuing with the share function...

      if let popOver = activityController.popoverPresentationController {
            popOver.sourceView = self.view
        }
        present(activityController, animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    
    // MARK: Functions that help move content out from behind the keyboard when it appears
    
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    
    @objc func keyboardWillShow(_ notification:Notification) {
        var activeTextField:UITextField
        if bottomText.isFirstResponder {
            activeTextField = bottomText
        } else {
            activeTextField = topText
        }
        let viewOffset = getViewOffset(textField: activeTextField, keyboardHeight: getKeyboardHeight(notification))
        
        if viewOffset != 0 {
            view.frame.origin.y -= viewOffset
        }
    }
    
  
    @objc func keyboardWillHide(_ notification:Notification) {
        view.frame.origin.y = 0
    }
   
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    
    
    /* This function calculates the distance the view should be shifted up to accomodate the keyboard.
     We don't move the view unless the keyboard will obstruct the text field in quesiton.
     I also didn't want to assume that the top text field would never be obstructed, so this function calculates an upward shift for any given text field if the keyboard would obstruct it.
     Question: could we use the keyboardTrackingLayoutGuide to do this, and how does that work?
     */
    
    func getViewOffset(textField:UITextField, keyboardHeight:CGFloat) -> CGFloat {
        let margin:CGFloat = 20.0
        var bottomOfTextField = textField.frame.maxY
        // If the text field is located in a superview, calculate its coordinates relative to the main view instead.
        let textFieldRect = textField.superview?.convert(textField.frame, to:view)
        if let rect = textFieldRect {
            bottomOfTextField = rect.maxY
        }
        let bottomOfScreen = view.frame.maxY
        let topOfKeyboard = bottomOfScreen - keyboardHeight
        if topOfKeyboard < bottomOfTextField + margin {
            return (bottomOfTextField - topOfKeyboard + 2 * margin)
        } else {
            return 0
        }
    }
    

    
    // MARK: Text field delegate functions
    

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        toggleShareButton()
        return true
    }
    
    
    // Presents an empty field to edit if user content has not been provided; otherwise allows the user to edit their previously entered text.
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField.text == textField.placeholder {
            textField.text = ""
        }
        return true
    }
   
    
    
    // MARK: Image Picker functions
    
    
    // Deals with a selected image
    func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
  
        /* Once the user picks an image, display it onscreen.
            Choose the edited version of the image to use, if there is one. */
        
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                myPhoto.image = image
            } else {
                
                if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    myPhoto.image = image
                } else {
                    
                    myPhoto.image = testImage // to help with debugging if there's a problem
                }}
            
        toggleShareButton()
        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
 
    // Turns the meme elements into a single image which can then be shared or saved.
    func generateMemedImage() -> UIImage {
        
       /* Instructions were to hide the toolbar, capture the image with the code given below, then show the toolbar, in order to capture the photo without the toolbar showing.
        
       Render view to an image
       UIGraphicsBeginImageContext(memeView.frame.size)
       drawHierarchy(in: memeView.frame, afterScreenUpdates: true)
       let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
       UIGraphicsEndImageContext()
        */
        
        
        /* I took a different approach. I wanted the user to be able to see exactly what the meme will look like without the toolbar obscuring part of the view.
         So I arranged the meme elements into a view called memeView, which is completely visible above the toolbar. The following code captures that view.
         */
        
        let renderer = UIGraphicsImageRenderer(size: memeView.bounds.size)
        let memedImage = renderer.image { ctx in
            memeView.drawHierarchy(in: memeView.bounds, afterScreenUpdates: true)
        }
        
        return memedImage
    }
    
    
    /* The share button is toggled after changes to the photo or either text field.
       If any of the elements are missing (photo or either text field) the share button is disabled.
     */
    func toggleShareButton() {
        if myPhoto.image == nil || topText.text == topText.placeholder || bottomText.text == bottomText.placeholder {
            shareButton.isEnabled = false
        } else {
            shareButton.isEnabled = true
        }
    }
    
}

