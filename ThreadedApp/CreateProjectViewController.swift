//
//  CreateProjectViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 21/10/2025.
//

import UIKit
import FirebaseAuth

class CreateProjectViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var currentUser: FirebaseAuth.User?
    
    @IBOutlet weak var projectNameField: UITextField!
    
    @IBOutlet weak var yarnNameField: UITextField!
    
    @IBOutlet weak var yarnTypeField: UITextField!
    
    @IBOutlet weak var yarnWeightField: UITextField!
    
    @IBOutlet weak var hookSizeField: UITextField!
    
    @IBOutlet weak var needleSizeField: UITextField!
    
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var imageView: UIImageView!
    
    weak var coreDatabaseController: CoreDatabaseProtocol?


    // Map out the Hook Sizes
    let hookSizes: [(code: Double, label: String)] = [
        (1.0, "UK 11 / 1.0 mm"),
        (1.25, "UK 10 / 1.25 mm"),
        (1.5, "UK 9 / 1.5 mm"),
        (1.75, "UK 8 / 1.75 mm"),
        (2.0, "UK 7 / 2.0 mm"),
        (2.25, "UK 6 / 2.25 mm"),
        (2.5, "UK 5 / 2.5 mm"),
        (2.75, "UK 4 / 2.75 mm"),
        (3.0, "UK 3 / 3.0 mm"),
        (3.25, "UK 2 / 3.25 mm"),
        (3.5, "UK 1 / 3.5 mm"),
        (3.75, "UK 0 / 3.75 mm"),
        (4.0, "UK 00 / 4.0 mm"),
        (4.5, "UK 0.5 / 4.5 mm"),
        (5.0, "UK 1.0 / 5.0 mm"),
        (5.5, "UK 2.0 / 5.5 mm"),
        (6.0, "UK 3.0 / 6.0 mm"),
        (6.5, "UK 4.0 / 6.5 mm"),
        (7.0, "UK 5.0 / 7.0 mm"),
        (8.0, "UK 6.0 / 8.0 mm"),
        (9.0, "UK 7.0 / 9.0 mm"),
        (10.0, "UK 8.0 / 10.0 mm")
    ]
    
    // Map out the Needle Sizes
    let needleSizes: [(code: Double, label: String)] = [
        (2.0, "2.0 mm / US 0 / UK 14"),
        (2.25, "2.25 mm / US 1 / UK 13"),
        (2.5, "2.5 mm / US 1.5 / UK 12"),
        (2.75, "2.75 mm / US 2 / UK 11"),
        (3.0, "3.0 mm / US 2.5 / UK 10"),
        (3.25, "3.25 mm / US 3 / UK 9"),
        (3.5, "3.5 mm / US 4 / UK 8"),
        (3.75, "3.75 mm / US 5 / UK 7"),
        (4.0, "4.0 mm / US 6 / UK 6"),
        (4.5, "4.5 mm / US 7 / UK 5"),
        (5.0, "5.0 mm / US 8 / UK 4"),
        (5.5, "5.5 mm / US 9 / UK 3"),
        (6.0, "6.0 mm / US 10 / UK 2"),
        (6.5, "6.5 mm / US 10.5 / UK 1"),
        (7.0, "7.0 mm / US 11 / UK 0"),
        (8.0, "8.0 mm / US 11.5 / UK 00"),
        (9.0, "9.0 mm / US 13 / UK 0"),
        (10.0, "10.0 mm / US 15 / UK 1")
    ]
    
    var activePickerData: [String] = []
    var activeTextField: UITextField?
    
    let pickerView = UIPickerView()
    
    // Store the selected codes
    var selectedHookSizeCode: Double = 0.0
    var selectedNeedleSizeCode: Double = 0.0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            print("User logged in: \(user.email ?? "")")
        } else {
            print("No user signed in")
        }

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate //access the AppDelegate
        coreDatabaseController = appDelegate?.coreDatabaseController
        
        pickerView.delegate = self
        pickerView.dataSource = self
       
        hookSizeField.inputView = pickerView
        needleSizeField.inputView = pickerView
        
        setupPickerAccessory()
       
        // Track which textfield is active
        hookSizeField.delegate = self
        needleSizeField.delegate = self

    }
    
    func displayMessage(title:String, message: String) {
        let alertController = UIAlertController(title: title, message: message,
         preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,
         handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: - Photo Methods
    
    /* Called when a user has selected a photo to be saved. */
    func imagePickerController(_ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
        imageView.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // When image picker has been cancelled, dismiss
        dismiss(animated: true, completion: nil)
    }
    @IBAction func choosePhoto(_ sender: Any) {
        let controller = UIImagePickerController()
        controller.allowsEditing = false
        controller.delegate = self
        let actionSheet = UIAlertController(title: nil, message: "Select Option:",
        preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { action in
        controller.sourceType = .camera
        self.present(controller, animated: true, completion: nil)
        }
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { action in
        controller.sourceType = .photoLibrary
        self.present(controller, animated: true, completion: nil)
        }
        let albumAction = UIAlertAction(title: "Photo Album", style: .default) { action in
        controller.sourceType = .savedPhotosAlbum
        self.present(controller, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
        actionSheet.addAction(cameraAction)
        }
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(albumAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    @IBAction func createProject(_ sender: Any) {
        
        // Ensure that project name is entered
        guard let name = projectNameField.text else{
            return
        }
        
        // Error Handling
        if name.isEmpty {
            let errorMsg = "Please enter a name for your project."
            
            // Display the error message
            displayMessage(title: "Not all fields are filled.", message: errorMsg)
            return
        }
        
        // Start to save the image file
        guard let image = imageView.image else{
            displayMessage(title: "Error", message: "Please select a photo")
            return
        }
        
        // Generate filename
        let timestamp = UInt(Date().timeIntervalSince1970)
        let filename = "\(timestamp).jpg"
        
        // Try to compress the image into data stream using jpeg compression
        guard let data = image.jpegData(compressionQuality: 0.8) else {
        displayMessage(title: "Error", message: "Image data could not be compressed")
        return
        }
        
        //Try to save into directory
        let pathsList = FileManager.default.urls(for: .documentDirectory, in:
        .userDomainMask)
        let documentDirectory = pathsList[0]
        let imageFile = documentDirectory.appendingPathComponent(filename)
        
        do{
            try data.write(to: imageFile)
        }catch {
            displayMessage(title: "Error", message: "\(error)")
        }
        
        // Map segmented control to Bool
        // 0 = WIP, 1 = Completed
        let isCompleted = statusSegmentedControl.selectedSegmentIndex == 1
        
        let yarnName = yarnNameField.text ?? "Not Specified"
        let yarnType = yarnTypeField.text ?? "Not Specified"
        let yarnWeight = yarnWeightField.text ?? "Not Specified"
        
        let _ = coreDatabaseController?.addProject(name: name, yarnName: yarnName, yarnType: yarnType, yarnWeight: yarnWeight, hookSize: selectedHookSizeCode, needleSize: selectedNeedleSizeCode, isCompleted: isCompleted, imageFile: filename, projectOwner: currentUser?.uid ?? "")
        
        coreDatabaseController?.cleanup()
        
        
        // Go back to all projects
//        navigationController?.popViewController(animated: true)
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    //https://riptutorial.com/ios/example/10333/replace-keyboard-with-uipickerview
    // MARK: - Picker Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return activePickerData.count
    }
    
    // MARK: - Picker Delegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return activePickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row < activePickerData.count else { return }
        
        if activeTextField == hookSizeField {
            let selected = hookSizes[row]
            hookSizeField.text = selected.label
            selectedHookSizeCode = selected.code
        } else if activeTextField == needleSizeField {
            let selected = needleSizes[row]
            needleSizeField.text = selected.label
            selectedNeedleSizeCode = selected.code
        }
    }
    
    // MARK: - Track which text field is active

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        if textField == hookSizeField {
            activePickerData = hookSizes.map {$0.label}
        } else if textField == needleSizeField {
            activePickerData = needleSizes.map { $0.label }
        }
        pickerView.reloadAllComponents()
        
        // Preselect picker
        if let selectedRow = activePickerData.firstIndex(of: textField.text ?? "") {
               pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
        } else {
               pickerView.selectRow(0, inComponent: 0, animated: false)
        }
    }
    
    //MARK: - Toolbar for picker
    func setupPickerAccessory() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        // Add cancel and done button to cancel or complete selection for better UX
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPicker))
        let flexibleSpace = UIBarButtonItem(systemItem: .flexibleSpace)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePicker))
        
        toolbar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)

        // Assign toolbar to text fields that use picker
        hookSizeField.inputAccessoryView = toolbar
        needleSizeField.inputAccessoryView = toolbar
    }
    
    @objc func cancelPicker() {
        view.endEditing(true)
    }

    @objc func donePicker() {
        view.endEditing(true)
    }

}
