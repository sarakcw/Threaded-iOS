//
//  PatternDetailsViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 3/11/2025.
//

import UIKit

class PatternDetailsViewController: UIViewController {
        
    var pattern: PatternData?
    
    @IBOutlet weak var imageViewContainer: UIView!
    
    @IBOutlet weak var patternImageView: UIImageView!
    
    @IBOutlet weak var artTypeTag: UIButton!
    
    @IBOutlet weak var difficultyTag: UIButton!
    
    @IBOutlet weak var patternNameLabel: UILabel!
    
    @IBOutlet weak var designAuthorLabel: UILabel!
    
    @IBOutlet weak var sizesTextLabel: UILabel!
    
    @IBOutlet weak var yarnWeightLabel: UILabel!
    
    @IBOutlet weak var yardageTextLabel: UILabel!
    
    @IBOutlet weak var hookNeedleSizeTextLabel: UILabel!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let pattern = pattern else { return }
        
        // Rounded corners
        patternImageView.layer.cornerRadius = 20
        patternImageView.layer.masksToBounds = true
        imageViewContainer.layer.cornerRadius = 20
        // Shadow on the image container
        imageViewContainer.layer.shadowColor = UIColor.black.cgColor
        imageViewContainer.layer.shadowOpacity = 0.25
        imageViewContainer.layer.shadowOffset = CGSize(width: 0.5, height: 6)
        imageViewContainer.layer.shadowRadius = 3
        imageViewContainer.layer.masksToBounds = false
        
        // Have the Image fill the container
        patternImageView.contentMode = .scaleAspectFill
        patternImageView.clipsToBounds = true
        
        if let firstPhoto = pattern.photos?.first,
           let urlString = firstPhoto.medium2URL {
            Task{
                await downloadImage(from: urlString)
            }
            
        }
        
        patternNameLabel.text = pattern.name
        designAuthorLabel.text = pattern.patternAuthor
        
        artTypeTag.setTitle(pattern.craft, for: .normal)
        
        if let difficulty = pattern.difficultyAverage {
            switch difficulty {
            case 0.1...2.9:
                difficultyTag.setTitle("Beginner", for: .normal)
                difficultyTag.isHidden = false
            case 3.0...5.9:
                difficultyTag.setTitle("Intermediate", for: .normal)
                difficultyTag.isHidden = false
            case 6.0...:
                difficultyTag.setTitle("Advanced", for: .normal)
                difficultyTag.isHidden = false
            default:
                difficultyTag.setTitle("", for: .normal)
                difficultyTag.isHidden = true // Hide the tag if no difficulty average is found for the pattern
            }
        } else {
            difficultyTag.setTitle("", for: .normal)
            difficultyTag.isHidden = true
            
        }
        
        sizesTextLabel.text = pattern.sizesAvailable == "" ? "One Size/Not Specified" : pattern.sizesAvailable
        yarnWeightLabel.text = pattern.yarnWeightDescription
        if let yardage = pattern.yardage{
            yardageTextLabel.text =  "\(yardage) m"

        } else{
            yardageTextLabel.text = "Not Specified"
        }
        hookNeedleSizeTextLabel.text = displayHookNeedleInfo(for: pattern.craft, sizes: pattern.patternNeedleSizes)
        
        
        
    }
        
    private func downloadImage(from urlString: String) async {
            let secureURLString = urlString.replacingOccurrences(of: "http://", with: "https://")
            guard let url = URL(string: secureURLString) else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    self.patternImageView.image = image
                }
            } catch {
                self.patternImageView.image = UIImage(systemName: "photo")
                print("Error downloading image:", error)
            }
        }
    
    func displayHookNeedleInfo(for craft: String?, sizes: [PatternData.NeedleSize]) -> String {
        if craft?.lowercased() == "crochet" { // Crochet only uses hooks
           let hooks = sizes.compactMap { needle in
               if let hook = needle.hook, !hook.isEmpty {
                   return "Hook \(hook) (\(needle.metric ?? 0) mm)"
               }
               return nil
           }
           return hooks.isEmpty ? "No hook size listed" : hooks.joined(separator: ", ")
       } else { // Kniitting and other crafts use uses needles
           let needles = sizes.compactMap { needle in
               var parts: [String] = []
               if let us = needle.us { parts.append("US \(us)") } // e.g. US 8.0
               if let metric = needle.metric { parts.append("\(metric) mm") } // e.g 4.0 mm
               return parts.isEmpty ? nil : parts.joined(separator: " / ")
           }
           return needles.isEmpty ? "No needle size listed" : needles.joined(separator: ", ")
       }
        
    }
    
    //https://developer.apple.com/documentation/uikit/uiapplication/open(_:options:completionhandler:)
    @IBAction func didTapRavelryButton(_ sender: Any) {
        if let url = pattern?.patternUrl{
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Fallback URL if no permalink
            if let fallbackURL = URL(string: "https://ravelry.com/patterns/library/") {
                UIApplication.shared.open(fallbackURL, options: [:], completionHandler: nil)
            }
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

}
