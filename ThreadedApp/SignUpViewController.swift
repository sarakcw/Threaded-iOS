//
//  SignUpViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 3/11/2025.
//

import UIKit
import FirebaseAuth


class SignUpViewController: UIViewController, AuthListener {

    weak var databaseController: FirebaseDatabaseProtocol?
    
    @IBOutlet weak var fnameField: UITextField!
    
    @IBOutlet weak var lnameField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signupContainer: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signupContainer.layer.cornerRadius = 20
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate //access the AppDelegate
        databaseController = appDelegate?.firebaseDatabaseController //store a reference to the databaseController

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Error Handling
    func displayMessage(title:String, message: String) {
            let alertController = UIAlertController(title: title, message: message,
             preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,
             handler: nil))
            
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }
    
    func isValidEmailFormat(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    func authFailed(error: Error) {
        let nsError = error as NSError
        if let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .emailAlreadyInUse:
                self.displayMessage(title: "Email Already Used", message: "Please try logging in instead.")
            case .weakPassword:
                self.displayMessage(title: "Weak Password", message: "Password must be at least 6 characters.")
            case .invalidEmail:
                self.displayMessage(title: "Invalid Email", message: "Please enter a valid email address.")
            default:
                self.displayMessage(title: "Sign Up Failed", message: "Please try again.")
            
            }
        }
    }
    
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        // Full name is required
        guard let firstName = fnameField.text, !firstName.isEmpty else {
            
                displayMessage(title: "All fields required", message: "Please enter your first name.")
                return
        }
        guard let lastName = lnameField.text, !lastName.isEmpty else {
            
                displayMessage(title: "All fields required", message: "Please enter your last name.")
                return
        }
        
        // Email is required
        guard let email = emailTextField.text, !email.isEmpty else {
                    displayMessage(title: "All fields required", message: "Please enter an email.")
                    return
                }
                
        // Password is required
        guard let password = passwordTextField.text, !password.isEmpty else {
            displayMessage(title: "All fields required", message: "Please enter a password.")
            return
        }
                
        // Check valid email format
        if !isValidEmailFormat(email){
            displayMessage(title: "Invalid Email", message: "Please enter a valid email addres.")
            return
        }
        
        databaseController?.authListener = self
        databaseController?.signUp(firstName: firstName, lastName: lastName,email: email, password: password)
        
    }
    
    func signingIn() {
        displayMessage(title: "Success!", message: "You're all set! Go back to the login page to log in.")

        // Do nothing, sign in at login page
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
