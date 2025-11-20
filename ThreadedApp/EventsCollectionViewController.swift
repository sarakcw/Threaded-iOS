//
//  EventsCollectionViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 21/9/2025.
//

import UIKit
import FirebaseAuth
import MapKit
import CoreLocation


class EventsCollectionViewController: UICollectionViewController, FirebaseDatabaseListener, UISearchResultsUpdating, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager = CLLocationManager() //start and stop updates for location changes
    var currentLocation: CLLocationCoordinate2D?
    
    var listenerType: ListenerType = .all // Listen to both changes in Events and UserEvents
    weak var databaseController: FirebaseDatabaseProtocol?
    
    let SECTION_EVENTS = 0
    let CELL_EVENTS = "EventsCell"
    var selectedSegmentIndex: Int = 1

    
    var events: [Event] = [] //For all events the user is going
    var filteredEvents: [Event] = [] // Array of events after filtering by time period
    var userEvents: [Event] = [] //For all events the user is going
    var currentUser: FirebaseAuth.User?


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
        
        databaseController?.addListener(listener: self)
        
        selectedSegmentIndex = 1 // This week segment


        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        

        // Request to use location of user
        let authorisationStatus = locationManager.authorizationStatus
        if authorisationStatus != .authorizedWhenInUse {
            print("requesting for location")
            locationManager.requestWhenInUseAuthorization()
        }
        if authorisationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        //Search Controller
        let searchController = UISearchController(searchResultsController: nil)
        
        //will update based on the search
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Events"
        
        
        // Add the search bar to the view controller
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        
        // This view controller decides how the search controller is presented
        definesPresentationContext = true

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.

        // Setup layout
        collectionView.collectionViewLayout = createLayout()

    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("displaying events")

        locationManager.startUpdatingLocation()
        
        // Configure navigation bar to be purple
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .violetColour
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationController?.navigationBar.isTranslucent = false
        

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
        
        locationManager.stopUpdatingLocation()
    }
    
    //MARK: - MapKit methods
    //Listen for any change in authorization
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
                locationManager.requestLocation() // fetch location only when allowed
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate // get the most-up-to-date location
        print("coordinates: \(currentLocation)")
       
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
        manager.stopUpdatingLocation()
    }
    
    
    // MARK: - DatabaseListener Methods

    func onUserEventsChange(change: DatabaseChange, userEvents: [Event]) {
        self.userEvents = userEvents
    }
    
    func onAllEventsChange(change: DatabaseChange, events: [Event]) {
        self.events = events.filter { event in
            if let eventDate = event.datetime{
                return eventDate >= Date()
            }else{
                return false
            }
        }
        filteredEvents = self.events
        applyFilter()

        collectionView.reloadData()
    }

    
    // MARK: - Compositional Layout
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            
            if sectionIndex == self.SECTION_EVENTS{
                
                // Configure the layout for Events Section
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .absolute(385))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10 // Spacing beween each group
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16) // Padding
                
                // add a header (for search bar and segmented control)
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                        heightDimension: .absolute(55))
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

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEventDetails",
           let eventDetailsViewController = segue.destination as? EventDetailsViewController,
           let indexPath = collectionView.indexPathsForSelectedItems?.first {
            let selectedEvent = filteredEvents[indexPath.item]
            eventDetailsViewController.event = selectedEvent
            eventDetailsViewController.isHosting = (selectedEvent.host == currentUser?.uid)
            
            // Check if the selected event is in the current user's UserEvent [Event]
            let hasJoined = eventDetailsViewController.hasJoined = userEvents.contains { userEvent in
                userEvent.id == selectedEvent.id
            }
            print("has joined: \(hasJoined)")
            
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case self.SECTION_EVENTS:
            return filteredEvents.count
        default:
            return 0
        }
    }
    

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == SECTION_EVENTS{
            let eventCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_EVENTS, for: indexPath) as! EventsCollectionViewCell

            // Display all the events from the database
            if indexPath.item < filteredEvents.count{
                let event = filteredEvents[indexPath.item]
                eventCell.configure(with: event)
            }
            
            return eventCell
        }
    
        return UICollectionViewCell()
    }
    
    //MARK: - Supplementary Element
    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        
        //set up header for All Events section
        guard kind == UICollectionView.elementKindSectionHeader,
                  indexPath.section == SECTION_EVENTS else {
                return UICollectionReusableView()
            }
        
        // Get the reusable view of the header
        let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: EventsHeaderCollectionReusableView.reuseIdentifier,
                for: indexPath
            ) as! EventsHeaderCollectionReusableView
        
        // Add action handler for segmented control
            header.eventsSegmentedControl.addTarget(self,
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
            print("Near You")
            
            guard let currentLocation = currentLocation else {
                    displayMessage(title: "Location Disabled", message: "To allow Threaded to use your location, go to Settings > Privacy > Location Services")
                    return
            }
            
            var nearbyEvents: [Event] = []
            
            for event in events{
                guard let lat = event.latitude, let lng = event.longitude else {
                       continue
                }
                
                // Retrieve the distance between current location and the potential event
                // If it is within 3km add it to the filtered events list
                let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                let eventLocation = CLLocation(latitude: lat, longitude: lng)
                let distance = userLocation.distance(from: eventLocation)
                print("distance: \(distance)")
                if distance < 3000 {
                    print("appending")
                    nearbyEvents.append(event)
                }
                
            }
            filteredEvents = nearbyEvents
           
        case 1:
            print("Second segment selected")
            print("This Week tapped")
            
            // Get the current calendar
            let calendar = Calendar.current
    
            filteredEvents = events.filter {
                 // Unwrap and skip if nil
                 guard let date = $0.datetime else { return false }
                 
                 // Get events that are in the current week
                 return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
             }

           
        case 2:
            print("Second segment selected")
            print("Upcoming tapped")
            //If the event's dateTime is nil, default to now, so it won't appear as a future event
            // '>' only keep events that are in the future
            filteredEvents = events.filter { ($0.datetime ?? Date()) > Date() }
        default:
            break
        }
        
        // Update your collection view or data source here
        collectionView.reloadData()
    }
    
    //MARK: - Searchbar config
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let text = searchController.searchBar.text, !text.isEmpty else {
            filteredEvents = events // reset when search bar is empty
            collectionView.reloadData()
            return
        }
        
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        //Check if there is a search item
        if searchText.count > 0 {
            //Filter the list
            filteredEvents = events.filter({ (event: Event) -> Bool in
            return (event.name?.lowercased().contains(searchText) ?? false)
        })
        } else {
            filteredEvents = events
        }
        collectionView.reloadData()
        
    }
    func displayMessage(title:String, message: String) {
            let alertController = UIAlertController(title: title, message: message,
             preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,
             handler: nil))
            self.present(alertController, animated: true, completion: nil)
    }


    // MARK: UICollectionViewDelegate
    
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        performSegue(withIdentifier: "showEventDetails", sender: indexPath)
//
//    }

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
