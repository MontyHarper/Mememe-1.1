//
//  ViewController.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 6/3/23.
//
//  This is the editor view controller, where memes are made and dreams fulfilled.
//

import UIKit
import TOCropViewController
import CropViewController


class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
 
    
// MARK: IBOutlets
    
    @IBOutlet weak var myPhoto: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var cropButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
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

    // Tracks the vertical offset of the view in order to keep the keyboard from obscuring the text.
    var viewIsRaisedBy = 0.0
    
    // Use to prevent text fields from reverting to original state when view is re-drawn.
    var textSetupIsComplete:Bool = false

    // Allows the editor to pass the updated meme back to the detail view controller.
    weak var delegate:DetailViewController?
    
    
// MARK: Lifecycle Methods
    
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allows user to dismiss the keyboard by tapping elsewhere
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        /*
         For me:
         The following lines will disable the camera button for a simulator.
         The #if, #else, and #endif commands speak to the compiler.
         The code in the #if block is compiled if targetEnvironment(simulator).
         The code in the #else block is compiled otherwise.
         
         For reviewer:
         I'm afraid I griped a bit at my last reviewer because I couldn't get that code to build.
         If that's you, sorry!
         As you pointed out, it was my own fault for leaving off the #'s!
         I had just never seen the # markers before and didn't know what they were so my brain didn't process them.
         */
        
#if targetEnvironment(simulator)
        cameraButton.isEnabled = false
#else
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
#endif
        
        topText.text = myMeme.topText
        bottomText.text = myMeme.bottomText
        reloadImage() // Loads the correct image based on device orientation.
        
        if !textSetupIsComplete {
            setupText(topText,bottomText) // Formats the text fields
        }
        
        toggleCrop() // Activates or deactivates crop button
        shareButton.isEnabled = myMeme.isSharable
    }
    
    
    
    /*
     This function is called whenever the device changes orientation.
     This allows for the image to be cropped differently for portrait vs. landscape.
     When the device is turned, the image switches.
     If the crop controller is visible, it gets dismissed, to prevent saving a crop in the wrong orientation.
     */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
   
        if let pvc = presentedViewController {
            if pvc is CropViewController {
                presentedViewController?.dismiss(animated: true, completion: nil)
            }
        }
        
        reloadImage() // Loads the correct image based on the new device orientation.
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
            toggleCrop() // Crop button should already be disabled if there is no image.
        }
    }

    
    
    @IBAction func saveMeme() {
        
        // Saves meme and dismisses the editor.
            saveMyMeme()
            // if we got here from the image view, this dismisses the editor
            delegate?.updateMeme(myMeme)
            delegate?.hidesBottomBarWhenPushed = true
            navigationController?.setNavigationBarHidden(false, animated: false)
            navigationController?.popViewController(animated: true)
            // if we got here from the saved memes view, this dismisses the editor
            dismiss(animated: true)
    }
    
    @IBAction func shareMeme() {

        saveMyMeme()
        
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
        
        if bottomText.isFirstResponder && viewIsRaisedBy == 0 {
            let keyboardHeight = getKeyboardHeight(notification)
            let frameOrigin = view.frame.origin.y
            view.frame.origin.y = frameOrigin - keyboardHeight
            toolbar.isHidden = true
            viewIsRaisedBy = keyboardHeight
        }
    }
    
    
    // Moves the view down as needed when the keyboard is dismissed and shows the toolbar.
    @objc func keyboardWillHide(_ notification:Notification) {
        
        if viewIsRaisedBy > 0 {
            let frameOrigin = view.frame.origin.y
            /*
             Note: this assumes the view frame hasn't moved?
             I suspect there may be rare edge cases where it has, which leaves the meme in an odd position.
             Difficult to pin down.
             */
            view.frame.origin.y = frameOrigin + viewIsRaisedBy
            bottomText.resignFirstResponder()
            viewIsRaisedBy = 0
        }
        toolbar.isHidden = false
    }
   
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    

    
    // MARK: Text field functions
    
    // Formats the text fields; this happens once when the editor is presented.
    func setupText(_ textFields:UITextField...) {
        for field in textFields {
            field.defaultTextAttributes = memeTextAttributes
            field.textAlignment = .center
            field.autocapitalizationType = .allCharacters
            // the field's placeholder text is used to replace an empty text field
            field.placeholder = field.text
        }
        
        textSetupIsComplete = true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text == "" {
            textField.text = textField.placeholder
        }
        textField.resignFirstResponder()
        return true
    }
    
    
    // Store new field values after editing and toggle the share button.
    func textFieldDidEndEditing(_ textField: UITextField) {
        if bottomText.text != Meme.bottomPlaceholder {
            myMeme.bottomText = bottomText.text ?? ""
        }
        if topText.text != Meme.topPlaceholder {
            myMeme.topText = topText.text ?? ""
        }
        shareButton.isEnabled = myMeme.isSharable
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
    
    
    // Saves a selected image to the meme.
    func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
          
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                        
            self.myPhoto.image = image
            myMeme.image = image
            dismiss(animated: false, completion: nil)
            
            } else {
                myPhoto.image = defaultImage // Should never happen.
            }
        
        toggleCrop()
        shareButton.isEnabled = myMeme.isSharable
    }
    
    
    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: Crop View Controller functions
    
    /*
     Presents the crop view controller, allowing the user to resize and reshape the image.
     The initial aspect ratio is set to that of the screen, so the meme will fill its available space.
     
     Note to self:
     If the user changes the aspect ratio, the final meme will end up with "wings" of blank space on either side.
     This seems to be a consequence of using "Aspect Fit." I spent a day trying to figure out how to get rid of those wings, but was unable to do so.
     Maybe I should present the crop view again, just before the user shares the meme, for a chance to cut off those wings?
     */
    
    func presentCropViewController(_ image:UIImage) {
        
        let cropView = CropViewController(image: image)
        cropView.delegate = self
        
        /*
         Sets the correct cropping frame (cropView) for the current device orientation,
         if it already exists.
         Setting cropView based on saved frames allows the user to fine-tune the crop as it was last set,
         rather than starting from scratch each time.
         
         If a frame has not been saved, the cropping frame defaults to the aspect ratio of the memeView.
         This allows the user to use a frame that will fill the available space.
         */
        
        let rect = memeView.frame
        let size = dimensions(rect) // returns short and long size values
        
        switch OKit.layoutStyle {
        case .horizontal:
            cropView.customAspectRatio = CGSize(width:size.long, height:size.short) // default aspect ratio
            if let rect = myMeme.cropFrameLandscape { // stored aspect ratio will override default
                cropView.imageCropFrame = rect
            }
        case .vertical:
            cropView.customAspectRatio = CGSize(width:size.short, height:size.long)
            if let rect = myMeme.cropFramePortrait {
                cropView.imageCropFrame = rect
            }
        }
        
        
        // Allow the user to change the aspect ratio on screen as desired.
        cropView.aspectRatioLockEnabled = false
        
        // Allows the user to choose from a menu of pre-set values for common aspect ratios.
        cropView.aspectRatioPickerButtonHidden = false
        
        // Dismisses crop view with no changes if cancelled.
        cropView.onDidFinishCancelled = { didFinishCancelled in
            self.dismiss(animated:true, completion:nil)
            }
        
        present(cropView, animated: true, completion: nil)
    }
    

    // handles the edited image once it has been cropped
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.myPhoto.image = image
        
        /*
         Note that orientation is not updated here.
         The cropped image and frame are saved according to the orientation from when the controller was presented.
         This should not have changed, or the controller would have been dismissed by viewWillTransition.
         */
        
        switch OKit.layoutStyle {
        case .vertical:
            myMeme.croppedImagePortrait = image
            myMeme.cropFramePortrait = cropRect
        case .horizontal:
            myMeme.croppedImageLandscape = image
            myMeme.cropFrameLandscape = cropRect
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
        
        let frame = myPhoto.frame
        let renderer = UIGraphicsImageRenderer(size: frame.size)
        let memedImage = renderer.image { ctx in
            memeView.drawHierarchy(in: frame, afterScreenUpdates: true)
        }
        
        return memedImage
    }
    
    
    func saveMyMeme() {
      
        // Capture and save the memed image
        let memedImage = generateMemedImage()
        myMeme.memedImage = memedImage
        
        // This allows access to the meme array for storage.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
        /*
         If myMeme is an update of an existing meme, replace the old meme with the new information.
         Otherwise, give myMeme an ID number for future reference and save it at the end of the array.
         */
        if let id = myMeme.id {
            appDelegate.memes.replaceSubrange(id...id, with:[myMeme])
        } else {
            myMeme.id = appDelegate.memes.count
            appDelegate.memes.append(myMeme)
        }
    }
    
    
    // Toggles the crop button; it should only be available when an image is present to crop.
    func toggleCrop() {
        if myPhoto.image == nil {
            cropButton.isEnabled = false
        } else {
            cropButton.isEnabled = true
            }
        }
    
    
    func reloadImage() {
        
        /*
         Checks orientation of device,
         then choses the appropriately cropped meme image to display; vertical or horizontal.
         If a cropped image does not exist for the current orientation, the uncropped image is used instead.
         */
        
        resetLayoutStyle()
        
        switch OKit.layoutStyle {
        case .vertical:
            if let image = myMeme.croppedImagePortrait {
                myPhoto.image = image
            } else {
                myPhoto.image = myMeme.image
            }
        case .horizontal:
            if let image = myMeme.croppedImageLandscape {
                myPhoto.image = image
            } else {
                myPhoto.image = myMeme.image
            }
        }
    }
    
        
}

