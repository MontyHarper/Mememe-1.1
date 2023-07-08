//
//  ViewController.swift
//  Mememe 1.1
//
//  Created by Monty Harper on 6/3/23.
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
    
    var myMeme:Meme!
    var myMemeID:Int!

            
    // Tracks the vertical offset of the view in order to keep the keyboard from obscuring the text.
    var viewIsRaisedBy = 0.0
    
    // Use to prevent text fields from reverting to original state when view is re-drawn.
    var textSetupIsComplete:Bool = false
    
    // Use to determine current orientation and crop accordingly. Orientation will be re-set when needed.
    
    enum Layout {
        case vertical, horizontal
    }
    
    let device = UIDevice.current
    var layoutStyle: Layout = .vertical

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
         The reason for the #if, #else, and #endif commands...
         These speak to the compiler.
         The code in the #if block is compiled if targetEnvironment(simulator).
         The code in the #else block is compiled otherwise.
         
         For reviewer:
         I'm afraid I griped at my last reviewer because I couldn't get that code to build.
         If that's you, sorry!
         It was my own fault for leaving off the #'s.
         I had just never seen that before and didn't know what it was so my brain didn't process it.
         */
        
#if targetEnvironment(simulator)
        cameraButton.isEnabled = false
#else
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
#endif
        
        topText.text = myMeme.topText
        bottomText.text = myMeme.bottomText
        resetLayoutStyle()
        loadImage()
        
        if !textSetupIsComplete {
            setupText(topText,bottomText) // Formats the text fields
        }
        
        toggleButtons() // Activates or deactivates crop and share buttons as appropriate
        
    }
    
    
    
    /*
     This function is called whenever the device changes orientation.
     This allows for the image to be cropped differently for portrait vs. landscape.
     When the device is turned, the image switches.
     If the crop controller is showing it gets dismissed, to prevent saving a crop in the wrong orientation.
     */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
   
        if let pvc = presentedViewController {
            if pvc is CropViewController {
                presentedViewController?.dismiss(animated: true, completion: nil)
            }
        }
        
       loadImage()
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
      
    // should call save, then share
        
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
                 Note that the original image and the cropped images and cropping frames are saved when they get selected or changed, so they should already be attached to myMeme.
                 I may decide to treat these properties the same way; that way if the user is interrupted while editing the meme they can come back to what they had. That's probably more of a Mememe 2.0 concern.
                 */
                self.myMeme.topText = self.topText.text!
                self.myMeme.bottomText = self.bottomText.text!
                self.myMeme.memedImage = memedImage
                
                let object = UIApplication.shared.delegate
                let appDelegate = object as! AppDelegate
                appDelegate.memes.append(self.myMeme)
                
                
            } else {
                debugPrint("The sharing activity was cancelled.")
            }

            if let error = activityError {
                debugPrint(error)
            }
            
            self.dismiss(animated: true, completion: nil)
        }
        
      if let popOver = activityController.popoverPresentationController {
            popOver.sourceView = self.view
        }
      present(activityController, animated: true, completion: nil)
    }
    
    
    @IBAction func saveMeme() {
        
        saveMyMeme()
        delegate?.updateMeme(myMeme)
        delegate?.hidesBottomBarWhenPushed = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.popViewController(animated: true)
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
    
    // Formats the text fields; this happens once when the app is launched.
    func setupText(_ textFields:UITextField...) {
        for field in textFields {
            field.defaultTextAttributes = memeTextAttributes
            field.textAlignment = .center
            field.autocapitalizationType = .allCharacters
            // placeholder text is initially set in storyboard, stored here & used to replace an empty text field
            field.placeholder = field.text
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
    
    
    // Saves a selected image to the meme.
    func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        print("User selected an image")
  
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            print("Image exists as a UIImage")
            
            self.myPhoto.image = image
            myMeme.image = image
            toggleButtons()
            dismiss(animated: false, completion: nil)
                
            } else {
                myPhoto.image = defaultImage // Should never happen.
            }
    }
    
    
    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: Crop View Controller functions
    
    /*
     Presents the crop view controller, allowing the user to resize and reshape the image.
     The initial aspect ratio is set to that of the screen, so the meme will fill its available space.
     If the user changes this, the final meme will end up with "wings" of blank space on either side.
     This seems to be a consequence of using "Aspect Fit." I spent a day trying to figure out how to get rid of those wings, but was unable to do so.
     I may want to look into providing a way of restoring that initial aspect ratio. There is currently no way to get back to it once the user changes it.
     Or experiment with "Aspect Fill."
     Another idea is to present the crop view again just before the user shares the meme, for a chance to cut off those wings.
     */
    
    
    
    func presentCropViewController(_ image:UIImage) {
        
        let cropView = CropViewController(image: image)
        cropView.delegate = self
        
        // Sets the initial cropping aspect ratio to fill the screen with the image.
        cropView.customAspectRatio = CGSize(width: memeView.frame.width, height: memeView.frame.height)
        
        // Allow the user to change the aspect ratio as needed.
        cropView.aspectRatioLockEnabled = false
        
        /*
         Selects the correct cropping frame (cropView) for the current device orientation,
         if it already exists. Otherwise the cropping frame defaults to the custom ratio set above.
         Setting cropView based on saved frames allows the user to fine-tune the crop as it was last set,
         rather than starting from scratch each time.
         */
        
        
        switch layoutStyle {
        case .vertical:
            if let rect = myMeme.cropFramePortrait {
                cropView.imageCropFrame = rect
            }
        case .horizontal:
            if let rect = myMeme.cropFrameLandscape {
                cropView.imageCropFrame = rect
            }
        }
        
        // Allows the user to choose from some pre-set values for common aspect ratios.
        cropView.aspectRatioPickerButtonHidden = false
        
        cropView.onDidFinishCancelled = { didFinishCancelled in
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
        
        switch layoutStyle {
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
      
        // Capture the memed image
        let memedImage = generateMemedImage()
        
        /*
         Set the myMeme properties that haven't been set yet.
         Note that image properties and cropping properties are not included here.
         Those get set and reset whenever images are selected or cropped by the user.
         */
        myMeme.topText = topText.text!
        myMeme.bottomText = bottomText.text!
        myMeme.memedImage = memedImage
        myMeme.isEmpty = false
        
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
    
    
    func shareMeme(_ meme:Meme) {
        // this might go onto a helper page that we import
        // tht way it can be accessed from the edit or the details view
    }
    
    
    /*
     Buttons are toggled after changes to the photo or either text field.
     If any of the elements are missing (photo or either text field) the share button is disabled.
     If no photo exists, the crop button is disabled.
     */
    func toggleButtons() {
    
        if myPhoto.image == nil || topText.text == topText.placeholder || bottomText.text == bottomText.placeholder {
            myMeme.isSharable = false
        } else {
            myMeme.isSharable = true
        }
        
        if myPhoto.image == nil {
            cropButton.isEnabled = false
        } else {
            cropButton.isEnabled = true
            }
        
        shareButton.isEnabled = myMeme.isSharable
        
        }
    
    func loadImage() {
        
        switch layoutStyle {
        case .vertical:
            if let image = myMeme.croppedImagePortrait {
                myPhoto.image = image
            }
        case .horizontal:
            if let image = myMeme.croppedImageLandscape {
                myPhoto.image = image
            }
        }
    }
    
    
    func resetLayoutStyle() {
        
        let orientation = device.orientation
        
        switch orientation {
        case .portrait, .portraitUpsideDown:
            layoutStyle = .vertical
        case .landscapeLeft, .landscapeRight:
            layoutStyle = .horizontal
        default:
            debugPrint("no change")
            // layout style will not change unless the device is turned to vertical or horizontal position.
        }
        
    }
}

