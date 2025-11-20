//
//  PatternsCollectionViewCell.swift
//  ThreadedApp
//
//  Created by Sara Kok on 2/10/2025.
//

import UIKit

class PatternsCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var patternImageView: UIImageView!
    private var imageTask: URLSessionDataTask? // keep tack of image download that is ongoing
    
    @IBOutlet weak var artTypeTag: UIButton!
    
    @IBOutlet weak var skillLevelTag: UIButton!
    
    @IBOutlet weak var patternNameLabel: UILabel!
    
    @IBOutlet weak var designerLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Rounded corners
        patternImageView.layer.cornerRadius = 20
        patternImageView.layer.masksToBounds = true
        imageContainerView.layer.cornerRadius = 20
        // Shadow on the image container
        imageContainerView.layer.shadowColor = UIColor.black.cgColor
        imageContainerView.layer.shadowOpacity = 0.25
        imageContainerView.layer.shadowOffset = CGSize(width: 0.5, height: 6)
        imageContainerView.layer.shadowRadius = 3
        imageContainerView.layer.masksToBounds = false
        
        // Have the Image fill the container
        patternImageView.contentMode = .scaleAspectFill
        patternImageView.clipsToBounds = true
        

    }
    func configure(with pattern: PatternData){
        // Display Art Type Tag
        patternNameLabel.text = pattern.name?.uppercased()
        designerLabel.text = pattern.patternAuthor ?? "Unknown"
        artTypeTag.setTitle(pattern.craft, for: .normal)
        
        if let difficulty = pattern.difficultyAverage {
            switch difficulty {
            case 0.1...2.9:
                skillLevelTag.setTitle("Beginner", for: .normal)
                skillLevelTag.isHidden = false
            case 3.0...5.9:
                skillLevelTag.setTitle("Intermediate", for: .normal)
                skillLevelTag.isHidden = false
            case 6.0...:
                skillLevelTag.setTitle("Advanced", for: .normal)
                skillLevelTag.isHidden = false
            default:
                skillLevelTag.setTitle("", for: .normal)
                skillLevelTag.isHidden = true // Hide the tag if no difficulty average is found for the pattern

            }
        } else {
            skillLevelTag.setTitle("", for: .normal)
            skillLevelTag.isHidden = true

        }
        
        if let firstPhoto = pattern.photos?.first,
           let urlString = firstPhoto.medium2URL,
           let url = URL(string: urlString) {
            // Set placeholder first
            patternImageView.image = UIImage(systemName: "photo")
            
            // Cancel any previous task
            imageTask?.cancel()
            
            // Start new image download
            imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self = self, let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.patternImageView.image = image
                }
            }
            imageTask?.resume()
        }


        

    }
}
