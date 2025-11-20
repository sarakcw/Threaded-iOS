//
//  NextEventCollectionViewCell.swift
//  ThreadedApp
//
//  Created by Sara Kok on 19/9/2025.
//

import UIKit

//https://www.advancedswift.com/corners-borders-shadows/#shadow-in-storyboard
@IBDesignable
class NextEventCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    // MARK: - Inspectable properties for Storyboard
    @IBInspectable var cornerRadius: CGFloat {
        get{ return contentView.layer.cornerRadius}
        set{
            contentView.layer.cornerRadius = newValue
            
            // If mask to bounds is true, the subviews will be clipped to the rounded corner
            contentView.layer.masksToBounds = (newValue > 0)
        }
    }
    @IBInspectable var shadowRadius: CGFloat {
        get { return layer.shadowRadius }
        set { layer.shadowRadius = newValue }
        }

        @IBInspectable var shadowOpacity: CGFloat {
            get { return CGFloat(layer.shadowOpacity) }
            set { layer.shadowOpacity = Float(newValue) }
        }

        @IBInspectable var shadowOffset: CGSize {
            get { return layer.shadowOffset }
            set { layer.shadowOffset = newValue }
        }

        @IBInspectable var shadowColor: UIColor? {
            get {
                guard let cgColor = layer.shadowColor else {
                    return nil
                }
                return UIColor(cgColor: cgColor)
            }
            set { layer.shadowColor = newValue?.cgColor }
        }
    
    override func awakeFromNib() {
            super.awakeFromNib()
            layer.masksToBounds = false // Shadows will not appear if this is true
            contentView.layer.masksToBounds = true // Keep content clipped
        }
    
    func configure(with event: Event) {
        titleLabel.text = "Event:  \(event.name ?? "Unknown")"
        
        // Format date to string
        if let date = event.datetime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: date)
            dateLabel.text = "Date: \(dateString)"
        } else {
            dateLabel.text = "Date: To be confirmed"
        }
        
        // Format time to string
        if let time = event.datetime{
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let timeString = timeFormatter.string(from: time)
            timeLabel.text = "Time: \(timeString)"
        } else{
            timeLabel.text = "To be confirmed"
        }
        
        // Set default image depending on art type
        switch event.artType{
        case 1:
            backgroundImageView.image = UIImage(named: "knitting")
        case 2:
            backgroundImageView.image = UIImage(named: "crochet")
        case 3:
            backgroundImageView.image = UIImage(named: "embroidery")
        default:
            backgroundImageView.image = UIImage(named: "AllCraftType")
        }

    }
}
