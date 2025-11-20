//
//  EventsCollectionReusableView.swift
//  ThreadedApp
//
//  Created by Sara Kok on 23/9/2025.
//

import UIKit

class EventsHeaderCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var eventsSegmentedControl: UISegmentedControl!
        
    static let reuseIdentifier = "EventsHeader"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Default selected index is 1 => This Week
        eventsSegmentedControl.selectedSegmentIndex = 1
    }
        
}
