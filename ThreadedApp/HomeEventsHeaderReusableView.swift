//
//  HomeEventsHeaderReusableView.swift
//  ThreadedApp
//
//  Created by Sara Kok on 20/9/2025.
//

import UIKit

class HomeEventsHeaderReusableView: UICollectionReusableView {
    static let reuseIdentifier = "HomeEventsHeader"
    
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func awakeFromNib(){ //Called after the UI View is loaded, to setup outlets properly
        
        // Default selected index is 0 => This Week
        segmentedControl.selectedSegmentIndex = 0

    }
    
}
