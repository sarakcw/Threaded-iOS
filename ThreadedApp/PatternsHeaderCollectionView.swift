//
//  PatternsHeaderCollectionView.swift
//  ThreadedApp
//
//  Created by Sara Kok on 4/10/2025.
//

import UIKit

class PatternsHeaderCollectionView: UICollectionReusableView {
    static let reuseIdentifier = "PatternsHeader"

    
    @IBOutlet weak var difficultySegmentedControl: UISegmentedControl!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            
            // Set default selection ( All)
        difficultySegmentedControl.selectedSegmentIndex = 0
        }
}
