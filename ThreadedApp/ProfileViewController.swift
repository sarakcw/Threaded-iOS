//
//  ProfileViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 7/11/2025.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    

    @IBOutlet weak var usernameLabel: UILabel!
    
    weak var databaseController: FirebaseDatabaseProtocol?
    weak var coreDatabaseController: CoreDatabaseProtocol?
    var currentUser: FirebaseAuth.User?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate //access the AppDelegate
        databaseController = appDelegate?.firebaseDatabaseController //store a reference to the databaseController
        coreDatabaseController = appDelegate?.coreDatabaseController
        
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            print("User logged in: \(user.email ?? "")")
        } else {
            print("No user signed in")
        }
        
        usernameLabel.text = "Loading..."
        Task {
            let username = await databaseController?.fetchUserName(uid: currentUser?.uid ?? "")
            usernameLabel.text = username ?? "User \(currentUser?.uid ?? "")"
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

    @IBAction func didSignoutTapped(_ sender: Any) {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { [weak self] _ in
            // Perform sign out
            self?.databaseController?.cleanup()
            self?.coreDatabaseController?.resetCache()
            self?.databaseController?.signOut()
            
            // Reset UI to login screen
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate else { return }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            
            sceneDelegate.window?.rootViewController = loginVC
            sceneDelegate.window?.makeKeyAndVisible()
        }))
        
        present(alert, animated: true, completion: nil)
    }
}
