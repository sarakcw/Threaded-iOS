//
//  ProjectDetailsViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 22/10/2025.
//

import UIKit

class ProjectDetailsViewController: UIViewController{

    var project: Project?

    weak var coreDatabaseController: CoreDatabaseProtocol?
    
    @IBOutlet weak var projectNameLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var yarnNameLabel: UILabel!
    
    @IBOutlet weak var yarnTypeLabel: UILabel!
    
    @IBOutlet weak var yarnWeightLabel: UILabel!
    
    @IBOutlet weak var hookSizeLabel: UILabel!

    @IBOutlet weak var needleSizeLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    
    @IBOutlet weak var toggleCompleteStatusButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        guard let project = project else {return}
        
        projectNameLabel.text = project.name
        yarnNameLabel.text = project.yarnName ?? "N/A"
        yarnTypeLabel.text = project.yarnType ?? "N/A"
        
        if let weight = project.yarnWeight, !weight.isEmpty {
            yarnWeightLabel.text = "\(weight)g"
        } else {
            yarnWeightLabel.text = "N/A"
        }
        
        hookSizeLabel.text = project.hookSize > 0 ? "\(String(format: "%.2f", project.hookSize)) mm" : "N/A"
        needleSizeLabel.text = project.needleSize > 0 ? "\(String(format: "%.2f", project.needleSize)) mm" : "N/A"
        statusLabel.text = project.isCompleted ? "Completed" : "Work-In-Progress"
        
        
        if let image = loadImageData(filename: project.imageFile ?? "") {
            imageView.image = image
            
            //https://stackoverflow.com/questions/27861383/how-to-set-corner-radius-of-imageview
            imageView.layer.cornerRadius = 10.0
            imageView.layer.masksToBounds = true
            imageView.contentMode = .scaleAspectFill 
            
        } else {
            imageView.image = UIImage(systemName: "photo") // fallback image
        }
        
        // Set the button title depending on project status
        if project.isCompleted{
            toggleCompleteStatusButton.setTitle("Mark as WIP", for: .normal)
            toggleCompleteStatusButton.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
        }else{
            toggleCompleteStatusButton.setTitle( "Mark as Complete", for: .normal)
            toggleCompleteStatusButton.setImage(UIImage(systemName: "square"), for: .normal)

        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure navigation bar to be purple
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .violetColour
        
        navigationController?.navigationBar.tintColor = UIColor.label

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationController?.navigationBar.isTranslucent = false

        
    }
    
    func loadImageData(filename: String) -> UIImage? {
        
        //retrieve document directory
        let paths = FileManager.default.urls(for: .documentDirectory,
        in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        // add the image file name to the directory path then attempt to load it into a UIImage
        let imageURL = documentsDirectory.appendingPathComponent(filename)
        let image = UIImage(contentsOfFile: imageURL.path)
        return image
    }
    
    
    @IBAction func toggleStatusTapped(_ sender: Any) {
        guard let project = project else {return}
        
        coreDatabaseController?.toggleProjectCompletion(project)
        
        // Update the button title
        if project.isCompleted {
            toggleCompleteStatusButton.setTitle("Mark as WIP", for: .normal)
            toggleCompleteStatusButton.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
        } else {
            toggleCompleteStatusButton.setTitle("Mark as Complete", for: .normal)
            toggleCompleteStatusButton.setImage(UIImage(systemName: "square"), for: .normal)

        }
        
        statusLabel.text = project.isCompleted ? "Completed" : "Work-In-Progress"
        
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
