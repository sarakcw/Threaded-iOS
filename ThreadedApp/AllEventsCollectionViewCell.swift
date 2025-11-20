//
//  AllEventsCollectionViewCell.swift
//  ThreadedApp
//
//  Created by Sara Kok on 19/9/2025.
//

import UIKit

//// Set up protocol to delete an event when a button has been tapped
//protocol AllEventsCellDelegate: AnyObject {
//    func didTapDelete(for event: Event)
//}

//@IBDesignable
class AllEventsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var eventImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var imageContainerView: UIView!
    
    // Delegate
//    weak var delegate: AllEventsCellDelegate?
    private var event: Event?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Rounded corners
        eventImageView.layer.cornerRadius = 20
        eventImageView.layer.masksToBounds = true
        imageContainerView.layer.cornerRadius = 20
        // Shadow on the image container
        imageContainerView.layer.shadowColor = UIColor.black.cgColor
        imageContainerView.layer.shadowOpacity = 0.25
        imageContainerView.layer.shadowOffset = CGSize(width: 0.5, height: 6)
        imageContainerView.layer.shadowRadius = 3
        imageContainerView.layer.masksToBounds = false
    }
    
    func configure(with event: Event){
        self.event = event
        
        titleLabel.text = "Event:  \(event.name ?? "Unknown")"
        
        // Format date to string
        if let date = event.datetime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: date)
            dateLabel.text = "Date: \(dateString)"
        } else {
            print("no date")
            dateLabel.text = "Date: To be confirmed"
        }
        
        // Format time to string
        if let time = event.datetime{
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: time)
            timeLabel.text = "Time: \(timeString)"
        } else{
            timeLabel.text = "Time: To be confirmed"
        }
        
 
        // Set default image depending on art type
        switch event.artType{
        case 1:
            eventImageView.image = UIImage(named: "knitting")
        case 2:
            eventImageView.image = UIImage(named: "crochet")
        case 3:
            eventImageView.image = UIImage(named: "embroidery")
        default:
            eventImageView.image = UIImage(named: "AllCraftType")
        }
        eventImageView.contentMode = .scaleAspectFill



        
    }
    
}
