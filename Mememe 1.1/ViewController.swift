//
//  ViewController.swift
//  Mememe 1.1
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
    
    // Use to determine current orientation and crop accordingly. Orientation will be re-set when needed.
    let device = UIDevice.current
    var orientation: UIDeviceOrientation = .portrait

    
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
    
    
    /*
     This function is called whenever the device changes orientation.
     This allows for the image to be cropped differently for portrait vs. landscape.
     The if appropriate cropped images exist, the image is switched when the device is turned.
     If the crop controller is showing it gets dismissed, to prevent saving a crop in the wrong orientation.
     */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
   
        if let pvc = presentedViewController {
            if pvc is CropViewController {
                presentedViewController?.dismiss(animated: true, completion: nil)
            }
        }
        
        orientation = device.orientation
        switch orientation {
        case .portrait, .portraitUpsideDown:
            if let image = myMeme.croppedImagePortrait {
                myPhoto.image = image
            }
        case .landscapeLeft, .landscapeRight:
            if let image = myMeme.croppedImageLandscape {
                myPhoto.image = image
            }
        default:
            print("no change")
        }
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
        
      /*
       completionWithItemsHandler is an enclosure attatched to the activity view controller.
       The view controller will execute this code when the user has completed or dismissed the activity.
       */
      activityController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            if completed {
                /*
                 Save the meme if the activity was completed.
                 Note that the original image and the cropped images are saved when they get selected or changed,
                 so they should already be attached to the myMeme.
                 */
                self.myMeme.topText = self.topText.text!
                self.myMeme.bottomText = self.bottomText.text!
                self.myMeme.memedImage = memedImage
                
            } else {
                print("The sharing activity was cancelled.")
            }

            if let error = activityError {
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
    
    
    // Moves the view up out of the way of the keyboard and hides the toolbar as needed.
    @objc func keyboardWillShow(_ notification:Notification) {
        
        if bottomText.isFirstResponder && !viewIsRaised {
            let keyboardHeight = getKeyboardHeight(notification)
            let frameOrigin = view.frame.origin.y
            view.frame.origin.y = frameOrigin - keyboardHeight
            toolbar.isHidden = true
            viewIsRaised = true
        }
    }
    
    
    // Moves the view down when the keyboard is dismissed and shows the toolbar as needed.
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
    
    
    /*
     Presents an empty field to edit if user content has not been provided.
     Otherwise, allows the user to edit their previously entered text.
     */
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField.text == textField.placeholder {
            textField.text = ""
        }
        return true
    }
   
    
    
    // MARK: Image Picker functions
    
    
    // Saves a selected image to the meme and sends it to the crop view controller to be cropped.
    func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
  
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            myMeme.image = image
            dismiss(animated: false, completion: nil)
            presentCropViewController(image) // Give the user a chance to crop the selected photo
                
            } else {
                myPhoto.image = defaultImage // Should never happen.
            }
    }
    
    
    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: Crop View Controller functions
    
    // Presents the crop view controller with settings allowing the user to resize the image keeping the aspect ratio of the photo view
    func presentCropViewController(_ image:UIImage) {
        let cropView = CropViewController(image: image)
        cropView.delegate = self
        cropView.customAspectRatio = CGSize(width: memeView.frame.width, height: memeView.frame.height)
        cropView.aspectRatioLockEnabled = true
        
        /*
         Selects the correct cropping frame (cropView) for the current device orientation,
         if it already exists. Otherwise the cropping frame defaults to the entire photo.
         Setting cropView based on saved frames allows the user to fine tune the crop as it was last set,
         rather than starting from scratch each time.
         */
        orientation = device.orientation
        switch orientation {
        case .portrait, .portraitUpsideDown:
            if let rect = myMeme.cropFramePortrait {
                cropView.imageCropFrame = rect
            }
        case .landscapeLeft, .landscapeRight:
            if let rect = myMeme.cropFrameLandscape {
                cropView.imageCropFrame = rect
            }
        default:
            print("No stored cropping frame.")
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
        
        /*
         Note that orientation is not updated here. The cropped image and frame are saved
         according to the orientation from when the controller was presented. This should not have changed,
         or the controller would have been dismissed by viewWillTransition.
         */
        switch orientation {
        case .portrait, .portraitUpsideDown:
            myMeme.croppedImagePortrait = image
            myMeme.cropFramePortrait = cropRect
        case .landscapeLeft, .landscapeRight:
            myMeme.croppedImageLandscape = image
            myMeme.cropFrameLandscape = cropRect
        default:
            print("No image stored.")
        }
        
        self.dismiss(animated: true, completion: nil)
   }
    
    
    // MARK: Other Functions
 
    
    // Captures the meme elements as a single image which can then be shared or saved.
    func generateMemedImage() -> UIImage {
        
        /*
         Instructions were to hide the toolbar, capture the image, then show the toolbar,
         in order to capture the photo without the toolbar showing.
         I took a different approach. I wanted the user to be able to see exactly what the meme will look like,
         so I arranged the meme elements above the toolbar in memeView.
         The following code captures memeView, toolbar not included.
         */
        let renderer = UIGraphicsImageRenderer(size: memeView.bounds.size)
        let memedImage = renderer.image { ctx in
            memeView.drawHierarchy(in: memeView.bounds, afterScreenUpdates: true)
        }
        
        return memedImage
    }
    
    
    
    /*
     Buttons are toggled after changes to the photo or either text field.
     If any of the elements are missing (photo or either text field) the share button is disabled.
     If no photo exists, the crop button is disabled.
     */
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

