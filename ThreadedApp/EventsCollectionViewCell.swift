//
//  EventsCollectionViewCell.swift
//  ThreadedApp
//
//  Created by Sara Kok on 21/9/2025.
//

import UIKit

class EventsCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageContainerView: UIView!
    
    @IBOutlet weak var eventsImageView: UIImageView!
    
    @IBOutlet weak var artTypeTag: UIButton!
    
    @IBOutlet weak var skillLevelTag: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Rounded corners
        eventsImageView.layer.cornerRadius = 20
        eventsImageView.layer.masksToBounds = true
        imageContainerView.layer.cornerRadius = 20
        // Shadow on the image container
        imageContainerView.layer.shadowColor = UIColor.black.cgColor
        imageContainerView.layer.shadowOpacity = 0.25
        imageContainerView.layer.shadowOffset = CGSize(width: 0.5, height: 6)
        imageContainerView.layer.shadowRadius = 3
        imageContainerView.layer.masksToBounds = false
        
        artTypeTag.layer.cornerRadius = 2
        artTypeTag.clipsToBounds = true
        
        skillLevelTag.layer.cornerRadius = 2
        skillLevelTag.clipsToBounds = true

    }
    
    func configure(with event: Event){        
        // Display Art Type Tag according to the int
        if event.artType == 0{
            artTypeTag.setTitle("All Art Types", for: .normal)
            eventsImageView.image = UIImage(named: "AllCraftType")
        }
        else if event.artType == 1 {
            artTypeTag.setTitle("Knitting", for: .normal)
            eventsImageView.image = UIImage(named: "knitting")

        }
        else if event.artType == 2 {
            artTypeTag.setTitle("Crochet", for: .normal)
            eventsImageView.image = UIImage(named: "crochet")

        }
        else if event.artType == 3 {
            artTypeTag.setTitle("Embroidery", for: .normal)
            eventsImageView.image = UIImage(named: "embroidery")

        }
        else{
            artTypeTag.setTitle("All Art Types", for: .normal)
            eventsImageView.image = UIImage(named: "AllCraftType")

        }
        eventsImageView.contentMode = .scaleAspectFill
        
        // Display Skill Level Tag according to the int
        if event.skillLevel == 0{
            skillLevelTag.setTitle("All Levels", for: .normal)
        }
        else if event.skillLevel == 1{
            skillLevelTag.setTitle("Beginner", for: .normal)
        }
        else if event.skillLevel == 2{
            skillLevelTag.setTitle("Intermediate", for: .normal)
        }
        else if event.skillLevel == 3{
            skillLevelTag.setTitle("Advance", for: .normal)
        }
        else{
            skillLevelTag.setTitle("All Levels", for: .normal)
        }
                
        titleLabel.text = event.name ?? "Unknown"
        
        // Format date to string
        if let date = event.datetime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: date)
            dateLabel.text = dateString
        } else {
            print("no date")
            dateLabel.text = "Date: To be confirmed"
        }
        
        // Format time to string
        if let time = event.datetime{
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: time)
            timeLabel.text = timeString
        } else{
            timeLabel.text = "Time: To be confirmed"
        }
        


    }
    
}
