//
//  ViewController.swift
//  Mememe 1.0
//
//  Created by Monty Harper on 6/3/23.
//

import UIKit
import TOCropViewController
import CropViewController

class ViewController: UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
 
    
// MARK: IBOutlets
    
    @IBOutlet weak var myPhoto: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var cropButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var memeView: UIView!


    
   
// MARK: Properties
    
    // Default image to use for testing purposes
    let defaultImage: UIImage = UIImage(named:"Sinclair-ZX81")!
    
    // Dictionary of text attributes for the meme top and bottom text
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        .strokeColor: UIColor.black,
        .foregroundColor: UIColor.white,
        .font: UIFont(name: "Impact", size: 40)!,
        .strokeWidth:  -4.0,
    ]
    
    // Struct instance in which to store the working meme.
    var myMeme = Meme()
            
    // Track whether the view is raised or lowered, to keep from raising or lowering when unnecessary.
    var viewIsRaised:Bool = false
    
    // Use to prevent text fields from reverting to original state when view is re-drawn.
    var textSetupIsComplete:Bool = false
    
    
    
// MARK: Lifecycle Methods
    
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        if !textSetupIsComplete {
            setupText(topText,bottomText) // Formats the text fields
        }
        toggleButtons() // Activates or deactivates crop and share buttons as appropriate
    }
    

    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topText.delegate = self
        bottomText.delegate = self
        // Allows user to dismiss the keyboard by tapping elsewhere
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
           view.addGestureRecognizer(tapGesture)
    }
    
    
    
//MARK: IBActions

    @IBAction func selectPhoto(_ sender: UIButton) {
       
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        
        // choose camera or photo album depending on which button was pressed
        switch sender {
        case cameraButton:
            pickerController.sourceType = .camera
        default:
            pickerController.sourceType = .photoLibrary
        }
       
        present(pickerController, animated: true, completion: nil)
    }

    
    @IBAction func crop() {
        if let image = myMeme.image {
            presentCropViewController(image)
        } else {
            toggleButtons() // Crop button should already be disabled if there is no image.
        }
    }
    
    
    @IBAction func share(_ sender: Any) {
      let memedImage = generateMemedImage()
      let activityController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
      /* completionWithItemsHandler is an enclosure attatched to the activity view controller, to be defined here.
       The view controller will execute this code when the user has completed or dismissed the activity. */
        
        activityController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            if completed {
                /* Save the meme if the activity was completed.
                   Note that the original image and the cropped image should already be saved */
                
                self.myMeme.topText = self.topText.text!
                self.myMeme.bottomText = self.bottomText.text!
                self.myMeme.memedImage = memedImage
                
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
        
      if let popOver = activityController.popoverPresentationController {
            popOver.sourceView = self.view
        }
        present(activityController, animated: true, completion: nil)
    }
    
    
    // Called by tapping outside of keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    
    // MARK: Functions that help move content up or down when keyboard appears or disappears
    
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    
    // Moves the view up out of the way of the keyboard
    @objc func keyboardWillShow(_ notification:Notification) {
        
        if bottomText.isFirstResponder && !viewIsRaised {
            let keyboardHeight = getKeyboardHeight(notification)
            let frameOrigin = view.frame.origin.y
            view.frame.origin.y = frameOrigin - keyboardHeight
            toolbar.isHidden = true
            viewIsRaised = true
        }
    }
    
    
    // Moves the view down when the keyboard is hidden
    @objc func keyboardWillHide(_ notification:Notification) {
        
        if viewIsRaised {
            let keyboardHeight = getKeyboardHeight(notification)
            let frameOrigin = view.frame.origin.y
            view.frame.origin.y = frameOrigin + keyboardHeight
            bottomText.resignFirstResponder()
            toolbar.isHidden = false
            viewIsRaised = false
        }
    }
   
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    

    
    // MARK: Text field functions
    
    // Formats the text fields
    func setupText(_ textFields:UITextField...) {
        for text in textFields {
            text.defaultTextAttributes = memeTextAttributes
            text.textAlignment = .center
            text.autocapitalizationType = .allCharacters
            // placeholder text is set in storyboard, stored here & used to replace an empty text field
            text.placeholder = text.text
            }
        textSetupIsComplete = true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text == "" {
            textField.text = textField.placeholder
        }
        toggleButtons()
        textField.resignFirstResponder()
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
  
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            myMeme.image = image
            myPhoto.image = image
            dismiss(animated: false, completion: nil)
     //       presentCropViewController(image) // Give the user a chance to crop the selected photo
                
            } else {
                myPhoto.image = defaultImage // to help with debugging if there's a problem
            }
    }
    
    
    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: Crop View Controller functions
    
    // presents the crop view controller with settings allowing the user to resize the image keeping the aspect ratio of the photo view
    func presentCropViewController(_ image:UIImage) {
        let cropView = CropViewController(image: image)
        cropView.delegate = self
        cropView.customAspectRatio = CGSize(width: memeView.frame.width, height: memeView.frame.height)
        cropView.aspectRatioLockEnabled = true
        // This thing is supposed change aspect ratio for landscape but not sure that it works well.
        cropView.aspectRatioLockDimensionSwapEnabled = true
        if let rect = myMeme.cropFrame {
            cropView.imageCropFrame = rect
        }
        cropView.aspectRatioPickerButtonHidden = true
        cropView.onDidFinishCancelled = { didFinishCancelled in
            self.myPhoto.image = image
            self.dismiss(animated:true, completion:nil)
            }
        present(cropView, animated: true, completion: nil)
    }

    // handles the edited image once it has been cropped
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.myPhoto.image = image
        myMeme.croppedImage = image
        myMeme.cropFrame = cropRect
        self.dismiss(animated: true, completion: nil)
   }
    
    
    // MARK: More Functions
 
    // Turns the meme elements into a single image which can then be shared or saved.
    func generateMemedImage() -> UIImage {
        
       /* Instructions were to hide the toolbar, capture the image, then show the toolbar, in order to capture the photo without the toolbar showing.
          I took a different approach. I wanted the user to be able to see exactly what the meme will look like without the toolbar obscuring part of the view.
          So I arranged the meme elements above the toolbar. The following code captures that view, without the toolbar.
        */
        
        let renderer = UIGraphicsImageRenderer(size: memeView.bounds.size)
        let memedImage = renderer.image { ctx in
            memeView.drawHierarchy(in: memeView.bounds, afterScreenUpdates: true)
        }
        
        return memedImage
    }
    
    
    /* Buttons are toggled after changes to the photo or either text field.
       If any of the elements are missing (photo or either text field) the share button is disabled.
       If no photo exists the crop button is disabled. */
    
    func toggleButtons() {
    
        if myPhoto.image == nil || topText.text == topText.placeholder || bottomText.text == bottomText.placeholder {
            shareButton.isEnabled = false
        } else {
            shareButton.isEnabled = true
        }
        if myPhoto.image == nil {
            cropButton.isEnabled = false
        } else {
            cropButton.isEnabled = true
            }
        }
    
}

