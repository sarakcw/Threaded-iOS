//
//  HomeCollectionViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 19/9/2025.
//

import UIKit
import FirebaseAuth



class HomeCollectionViewController: UICollectionViewController, FirebaseDatabaseListener{
    
    var listenerType: ListenerType = .userEvents
    weak var databaseController: FirebaseDatabaseProtocol?

    let TOTAL_SECTIONS = 2
    let SECTION_NEXT_EVENT = 0
    let SECTION_ALL_EVENTS = 1
    
    let CELL_NEXT_EVENT = "NextEventCell"
    let CELL_ALL_EVENTS = "AllEventsCell"
        
    var currentUser: FirebaseAuth.User?
    
    var userEvents: [Event] = [] //For all events the user is going
    var filteredUserEvents: [Event] = [] // Array of events after filtering by time period
    
    var selectedEvent: Event?
    var selectedSegmentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.firebaseDatabaseController
        
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            print("User logged in: \(user.email ?? "")")
        } else {
            print("No user signed in")
        }
        
        selectedSegmentIndex = 0

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    
        // Setup layout
        collectionView.collectionViewLayout = createLayout()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)

        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // MARK: - DatabaseListener Methods

    func onUserEventsChange(change: DatabaseChange, userEvents: [Event]) {
        
        // Only show events from today onwards
        self.userEvents = userEvents.filter{ event in
            if let eventDate = event.datetime{
                return eventDate >= Date()
            }else {
                return false
            }
        }
        // Sort by date, nearest date first
        .sorted { event1, event2 in
                guard let date1 = event1.datetime, let date2 = event2.datetime else { return false }
                return date1 < date2
        }
        filteredUserEvents = self.userEvents
        applyFilter() // Apply segment filter when this view loads

        collectionView.reloadData()
    }
    
    func onAllEventsChange(change: DatabaseChange, events: [Event]) {
        //do nothing
    }
    
    func didTapDelete(for event: Event) {
            databaseController?.deleteEvent(event: event)
            
    }
    
    // MARK: - Compositional Layout
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in

            if sectionIndex == self.SECTION_NEXT_EVENT{
                
                // Configure the layout for Next Event Section
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .absolute(200))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16) // Padding
                return section
                
            } else if sectionIndex == self.SECTION_ALL_EVENTS{
                
                // Configure the layout for All Events Section

                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .absolute(330))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10 // Spacing beween each group
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16) // Padding
                
                // add a header (for title and segmented control)
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                        heightDimension: .absolute(120))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
            }
            else{
                return nil
            }
            
        }
        return layout
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "showEventDetails",
           let destinationViewController = segue.destination as? EventDetailsViewController,
        let selectedEvent = sender as? Event{
            destinationViewController.event = selectedEvent
            destinationViewController.isHosting = (selectedEvent.host == currentUser?.uid)
            destinationViewController.hasJoined = userEvents.contains { userEvent in
                userEvent.id == selectedEvent.id
            }
        }
           
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return TOTAL_SECTIONS
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
            case SECTION_NEXT_EVENT:
                return userEvents.isEmpty ? 0 : 1
            case SECTION_ALL_EVENTS:
                return filteredUserEvents.count
        default:
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        if indexPath.section == SECTION_NEXT_EVENT{
            let nextEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_NEXT_EVENT, for: indexPath) as! NextEventCollectionViewCell

            // Display the next event if there is an event
            if let event = userEvents.first {
                nextEventCell.configure(with: event)
            }
            
            return nextEventCell
        }
        else if indexPath.section == SECTION_ALL_EVENTS{
            let allEventsCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ALL_EVENTS, for: indexPath) as! AllEventsCollectionViewCell

            // Display the events if there are any user events
            if indexPath.item < filteredUserEvents.count{
                let event = filteredUserEvents[indexPath.item]
                allEventsCell.configure(with: event)
            }

            return allEventsCell
            
        }
        else{
            return UICollectionViewCell()
        }
    }
    
    //MARK: - Supplementary Element
    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        
        //set up header for All Events section
        guard kind == UICollectionView.elementKindSectionHeader,
                  indexPath.section == SECTION_ALL_EVENTS else {
                return UICollectionReusableView()
            }
        
        // Get the reusable view of the header
        let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: HomeEventsHeaderReusableView.reuseIdentifier,
                for: indexPath
            ) as! HomeEventsHeaderReusableView
        
        // Add action handler for segmented control
        header.segmentedControl.addTarget(self,
            action: #selector(filterChanged(_:)),
            for: .valueChanged)
        
        return header
    }
    
    @objc func filterChanged(_ sender: UISegmentedControl){
        selectedSegmentIndex = sender.selectedSegmentIndex
        applyFilter()
    }
    
    @objc func applyFilter() {
        switch selectedSegmentIndex {
        case 0:
            print("First segment selected")
            print("This week tapped")
   
            // Get the current calendar
            let calendar = Calendar.current
   
            filteredUserEvents = userEvents.filter {
                // Unwrap and skip if nil
                guard let date = $0.datetime else { return false }
                
                // Get events that are in the current week
                return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
            }
    
        case 1:
            print("Second segment selected")
            print("Upcoming tapped")

            //If the event's dateTime is nil, default to now, so it won't appear as a future event
            // '>' only keep events that are in the future
            filteredUserEvents = userEvents.filter { ($0.datetime ?? Date()) > Date() }
        case 2:
            print("Second segment selected")
            print("Hosting tapped")
            filteredUserEvents = userEvents.filter { $0.host == currentUser?.uid }
        default:
            break
        }
        
        // Update your collection view or data source here
        collectionView.reloadData()
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == SECTION_NEXT_EVENT{
            selectedEvent = userEvents.first // redo later
        }
        else if indexPath.section == SECTION_ALL_EVENTS{
            selectedEvent = filteredUserEvents[indexPath.item]
            
        }
        
        if let event = selectedEvent{
            performSegue(withIdentifier: "showEventDetails", sender: event)
        }

    }


    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
