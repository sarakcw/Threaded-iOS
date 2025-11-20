//
//  AllProjectsTableViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 21/10/2025.
//

import UIKit
import FirebaseAuth

class AllProjectsTableViewController: UITableViewController , CoreDatabaseListener{
    var currentUser: FirebaseAuth.User?
    
    let SECTION_WIP_PROJECT = 0
    let SECTION_COMPLETED_PROJECT = 1
    
    let CELL_WIP_PROJECT = "wipProjectCell"
    let CELL_COMP_PROJECT = "completedProjectCell"

    var allProjects: [Project] = []
    var filteredProjects: [Project] = []
    
    var listenerType = CoreListenerType.projects
    weak var coreDatabaseController: CoreDatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            print("User logged in: \(user.email ?? "")")
        } else {
            print("No user signed in")
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        coreDatabaseController = appDelegate?.coreDatabaseController
        filteredProjects = allProjects

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - View Configuration
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        coreDatabaseController?.addListener(listener: self)
        
        // Configure navigation bar to be purple
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .violetColour
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationController?.navigationBar.isTranslucent = false
        
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coreDatabaseController?.removeListener(listener: self)
    }
        
    func onAllProjectsChange(change: CoreDatabaseChange, projects: [Project]) {
        // Only get projects associated with this current user
        allProjects = projects
        guard let userId = currentUser?.uid else {
            filteredProjects = []
            tableView.reloadData()
            return
        }
        filteredProjects = allProjects.filter { $0.projectOwner == userId }
        tableView.reloadData()

    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case SECTION_WIP_PROJECT:
            return  filteredProjects.filter { !$0.isCompleted }.count
        case SECTION_COMPLETED_PROJECT:
            return filteredProjects.filter{ $0.isCompleted }.count
        default:
            return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure and return a project cell
        if indexPath.section == SECTION_WIP_PROJECT {
            let projectCell = tableView.dequeueReusableCell(withIdentifier: CELL_WIP_PROJECT, for: indexPath)
            var content = projectCell.defaultContentConfiguration()
            let project = filteredProjects.filter { !$0.isCompleted }[indexPath.row]
            content.text = project.name
            content.textProperties.color = .white // For accessability, ensure text is readable in front of background image
            content.textProperties.font = .boldSystemFont(ofSize: 20)
            projectCell.contentConfiguration = content
            
            // Setting the background image of the cell
            let imagePath = project.imageFile ?? ""
            // get access to the app's document directory
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(imagePath)
            
            if let image = UIImage(contentsOfFile: fileURL.path) { // Load image from disk
                
                //https://stackoverflow.com/questions/34111443/how-to-add-background-image-and-let-it-under-uitableviewcell-in-swift
                let backgroundImageView = UIImageView(image: image)
                
                //https://developer.apple.com/documentation/uikit/uiimageview
                backgroundImageView.contentMode = .scaleAspectFill
                backgroundImageView.clipsToBounds = true
                
                projectCell.backgroundView = backgroundImageView
                
                // Add overlay for more readability
                let overlay = UIView(frame: projectCell.contentView.bounds)
                overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                projectCell.backgroundView?.addSubview(overlay)
                
            } else {
                projectCell.backgroundView = nil // fallback
            }
            
            return projectCell
        }
        else{
            let compProjectCell = tableView.dequeueReusableCell(withIdentifier: CELL_COMP_PROJECT, for: indexPath)
            var content = compProjectCell.defaultContentConfiguration()
            let project = filteredProjects.filter { $0.isCompleted }[indexPath.row]
            content.text = project.name
            content.textProperties.color = .white // For accessability, ensure text is readable in front of background image
            content.textProperties.font = .boldSystemFont(ofSize: 20)
            compProjectCell.contentConfiguration = content
            
            // Setting the background image of the cell
            let imagePath = project.imageFile ?? ""
            // get access to the app's document directory
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(imagePath)
            
            if let image = UIImage(contentsOfFile: fileURL.path) { // Load image from disk
                
                //https://stackoverflow.com/questions/34111443/how-to-add-background-image-and-let-it-under-uitableviewcell-in-swift
                let backgroundImageView = UIImageView(image: image)
                
                //https://developer.apple.com/documentation/uikit/uiimageview
                backgroundImageView.contentMode = .scaleAspectFill
                backgroundImageView.clipsToBounds = true
                
                compProjectCell.backgroundView = backgroundImageView
                
                // Add overlay for more readability
                let overlay = UIView(frame: compProjectCell.contentView.bounds)
                overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                compProjectCell.backgroundView?.addSubview(overlay)
                
            } else {
                compProjectCell.backgroundView = nil // fallback
            }
            return compProjectCell
            
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedProject: Project
        if indexPath.section == SECTION_WIP_PROJECT {
            selectedProject = filteredProjects.filter { !$0.isCompleted }[indexPath.row]
        } else {
            selectedProject = filteredProjects.filter { $0.isCompleted }[indexPath.row]
        }
            
        // Trigger segue and pass the selected project
        performSegue(withIdentifier: "showProjectDetails", sender: selectedProject)
        
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete && indexPath.section == SECTION_WIP_PROJECT{
            let project = filteredProjects.filter{!$0.isCompleted}[indexPath.row]
            coreDatabaseController?.deleteProject(project: project)
            coreDatabaseController?.cleanup()
            
        }
        
        if editingStyle == .delete && indexPath.section == SECTION_COMPLETED_PROJECT{
            let project = filteredProjects.filter{$0.isCompleted}[indexPath.row]
            coreDatabaseController?.deleteProject(project: project)
            coreDatabaseController?.cleanup()

        }
    }
    
    // MARK: - Table header configuration
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SECTION_WIP_PROJECT:
            return "Work In Progress"
        case SECTION_COMPLETED_PROJECT:
            return "Completed"
        default:
            return nil
        }
    }
    
   //https://developer.apple.com/documentation/uikit/uitableviewdelegate/tableview(_:heightforheaderinsection:)/
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
   //https://stackoverflow.com/questions/19802336/changing-font-size-for-uitableview-section-headers
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 28)
        header.textLabel?.textColor = UIColor(named: "SageColor")
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showProjectDetails",
               let destination = segue.destination as? ProjectDetailsViewController,
               let project = sender as? Project {
                destination.project = project
                destination.coreDatabaseController = coreDatabaseController
        }
    }
    

}
