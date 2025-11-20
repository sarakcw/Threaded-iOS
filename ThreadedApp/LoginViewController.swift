//
//  LoginViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 23/9/2025.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, AuthListener {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginContainer: UIView!
    
    weak var databaseController: FirebaseDatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginContainer.layer.cornerRadius = 20
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate //access the AppDelegate
        databaseController = appDelegate?.firebaseDatabaseController //store a reference to the databaseController


        
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
            case .userNotFound:
                self.displayMessage(title:"User Not Found", message: "No account found for this email, please sign up")
            case .wrongPassword:
                self.displayMessage(title:"Incorrect password.", message: "Please try again.")
            default:
                self.displayMessage(title: "Sign In Failed", message: "Please try again.")
            }
        }
    }

    
    // MARK: - Process credentials
    @IBAction func loginButton(_ sender: Any) {
        // Email is required
        guard let email = emailTextField.text, !email.isEmpty else {
            displayMessage(title: "Error", message: "Please enter an email.")
            return
        }
        
        // Password is required
        guard let password = passwordTextField.text, !password.isEmpty else {
            displayMessage(title: "Error", message: "Please enter a password.")
            return
        }
        
        // Check for valid email format
        if !isValidEmailFormat(email){
            displayMessage(title: "Error", message: "Please enter a valid email addres.")
            return
        }
        
        databaseController?.authListener = self
        databaseController?.logIn(email: email, password: password)


    }
    
    
    // MARK: - Navigation
     func signingIn() { // Navigate to Home Screen
             DispatchQueue.main.async {
                 self.performSegue(withIdentifier: "showHomeScreen", sender: self)
             }
         }
    

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
