//
//  CreateEventViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 17/9/2025.
//

import UIKit
import CoreLocation

class CreateEventViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var eventNameTextField: UITextField!
    
    @IBOutlet weak var descriptionTextField: UITextField!
    
    @IBOutlet weak var locationTextField: UITextField!
    
    @IBOutlet weak var dateTimePicker: UIDatePicker!
        
    @IBOutlet weak var fiberArtTypeTextField: UITextField!
    
    @IBOutlet weak var skillLevelTextField: UITextField!
    
    @IBOutlet weak var capacityTextField: UITextField!
    
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    weak var databaseController: FirebaseDatabaseProtocol?


    // Map art type to their codes
    let artTypes = [
        (code: 0, label: "All"),
        (code: 1, label: "Knit"),
        (code: 2, label: "Crochet"),
        (code: 3, label: "Embroidery")
    ]
    
    // Map skill levels to their codes
    let skillLevels = [
        (code: 0, label: "All"),
        (code: 1, label: "Beginner"),
        (code: 2, label: "Intermediate"),
        (code: 3, label: "Advanced")
    ]
    
    var activePickerData: [String] = []
    var activeTextField: UITextField?
    
    let pickerView = UIPickerView()
    
    // Store the selected codes
    var selectedArtTypeCode: Int?
    var selectedSkillLevelCode: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate //access the AppDelegate
        databaseController = appDelegate?.firebaseDatabaseController //store a reference to the databaseController

        
        // Change the navigation bar title text color
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        // Change the tint color for bar button items (back button, right button, etc.)
        navigationController?.navigationBar.tintColor = UIColor.label
        
        datePicker.minimumDate = Date()// disable all earlier dates
        
        pickerView.delegate = self
        pickerView.dataSource = self
       
        fiberArtTypeTextField.inputView = pickerView
        skillLevelTextField.inputView = pickerView
        
        setupPickerAccessory()
       
        // Track which textfield is active
        fiberArtTypeTextField.delegate = self
        skillLevelTextField.delegate = self

    }
    
    func displayMessage(title:String, message: String) {
            let alertController = UIAlertController(title: title, message: message,
             preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,
             handler: nil))
            self.present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func createEvent(_ sender: Any) {

        // No emtpy fields except image
       guard let name = eventNameTextField.text,
             let about = descriptionTextField.text,
             let locationText = locationTextField.text,
             let artType = fiberArtTypeTextField.text,
             let skillLevel = skillLevelTextField.text,
             let capacity = capacityTextField.text else {
           
           displayMessage(title: "Fields Missing", message: "Fill in all the fields to create an event.")
           return
       }
        
        let datetimePicked = dateTimePicker.date

        // Error handling
        if name.isEmpty || about.isEmpty || locationText.isEmpty || artType.isEmpty || skillLevel.isEmpty || capacity.isEmpty {
            
            var errorMsg = "Please ensure all fields are filled:\n"
       
            if name.isEmpty {
                errorMsg += "- Must provide an event name"
            }
            if about.isEmpty {
                errorMsg += "- Must provide a short description of the event"
            }
            if locationText.isEmpty {
                errorMsg += "- Must provide a address"
            }
            if artType.isEmpty {
                errorMsg += "- Must provide art type "
            }
            if skillLevel.isEmpty {
                errorMsg += "- Must provide skill level"
            }
            if capacity.isEmpty {
                errorMsg += "- Must provide capacity"
            }
           
           displayMessage(title: "Not all fields filled", message: errorMsg)
           return
        }
        
        // Convert capacity from string to int
        guard let capacityText = capacityTextField.text,
              let capacity = Int(capacityText) else {
            displayMessage(title: "Invalid Input", message: "Capacity must be a number")
            return
        }
        
        //Convert location to coordinates and save
        //https://stackoverflow.com/questions/42279252/convert-address-to-coordinates-swift
        let geocoder = CLGeocoder()
        
        // Convert location to coordinates
        // Use weak self to prevent memory leaks after controller closes
        geocoder.geocodeAddressString(locationText) { [weak self] placemarks, error in
            
            guard let self = self else { return }
            
            var lat: Double? = nil
            var lng: Double? = nil
            
            if let coordinate = placemarks?.first?.location?.coordinate {
                    lat = coordinate.latitude
                    lng = coordinate.longitude
                } else {
                    print("Unable to retrieve coordinates for location: \(locationText)")
            }
            
            print("saving new event")
            
            let _ = self.databaseController?.addEvent(name: name, about: about, datetime: datetimePicked, address: locationText, artType: selectedArtTypeCode ?? 0, skillLevel: selectedSkillLevelCode ?? 0, capacity: capacity, latitude: lat, longitude: lng)
            self.navigationController?.popViewController(animated: true) // go back to home page

        }
        
        
        
    }
    
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
        if activeTextField == fiberArtTypeTextField {
            let selected = artTypes[row]
            fiberArtTypeTextField.text = selected.label
            selectedArtTypeCode = selected.code
        } else if activeTextField == skillLevelTextField {
            let selected = skillLevels[row]
            skillLevelTextField.text = selected.label
            selectedSkillLevelCode = selected.code
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
    
    // MARK: - Track which text field is active

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        if textField == fiberArtTypeTextField {
            activePickerData = artTypes.map {$0.label}
        } else if textField == skillLevelTextField {
            activePickerData = skillLevels.map { $0.label }
        }
        pickerView.reloadAllComponents()
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
        fiberArtTypeTextField.inputAccessoryView = toolbar
        skillLevelTextField.inputAccessoryView = toolbar
    }
    
    @objc func cancelPicker() {
        view.endEditing(true)
    }

    @objc func donePicker() {
        view.endEditing(true)
    }

}


