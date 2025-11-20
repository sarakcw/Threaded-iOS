//
//  EventDetailsViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 8/10/2025.
//

import UIKit
import MapKit
import CoreLocation


class EventDetailsViewController: UIViewController {
    var event: Event?
    var isHosting: Bool = false
    var hasJoined: Bool = false
    
    weak var databaseController: FirebaseDatabaseProtocol?

    @IBOutlet weak var imageContainer: UIView!
    
    @IBOutlet weak var eventImageView: UIImageView!
    
    @IBOutlet weak var artTypeTag: UIButton!
    
    @IBOutlet weak var skillLevelTag: UIButton!
    
    @IBOutlet weak var eventNameLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var capacityLabel: UILabel!
    
    @IBOutlet weak var hostLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    @IBOutlet weak var actionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.firebaseDatabaseController

        // Do any additional setup after loading the view.
        
        // Rounded corners
        eventImageView.layer.cornerRadius = 20
        eventImageView.layer.masksToBounds = true
        imageContainer.layer.cornerRadius = 20
        // Shadow on the image container
        imageContainer.layer.shadowColor = UIColor.black.cgColor
        imageContainer.layer.shadowOpacity = 0.25
        imageContainer.layer.shadowOffset = CGSize(width: 0.5, height: 6)
        imageContainer.layer.shadowRadius = 3
        imageContainer.layer.masksToBounds = false
        
        guard let event = event else {
            displayMessage(title: "Event Not Found", message: "This event has been cancelled.") // display error message
            return
        }
        
        // Set Art Type Tag and Default Image the corresponds to the art type
        switch event.artType{
        case 0:
            artTypeTag.setTitle("All Art Types", for: .normal)
            eventImageView.image = UIImage(named: "AllCraftType")
        
        case 1:
            artTypeTag.setTitle("Knitting", for: .normal)
            eventImageView.image = UIImage(named: "knitting")
            
        case 2:
            artTypeTag.setTitle("Crochet", for: .normal)
            eventImageView.image = UIImage(named: "crochet")
            
        case 3:
            artTypeTag.setTitle("Embroidery", for: .normal)
            eventImageView.image = UIImage(named: "embroidery")
        default:
            artTypeTag.setTitle("All Art Types", for: .normal)
            eventImageView.image = UIImage(named: "AllCraftType")
            
        }
        eventImageView.contentMode = .scaleAspectFill
        switch event.skillLevel{
        case 0:
            skillLevelTag.setTitle("All Skill Levels", for: .normal)
        case 1:
            skillLevelTag.setTitle("Beginner", for: .normal)
        case 2:
            skillLevelTag.setTitle("Intermediate", for: .normal)
        case 3:
            skillLevelTag.setTitle("Advance", for: .normal)
        default:
            skillLevelTag.setTitle("All Skill Levels", for: .normal)

        }
        
        if isHosting {
            actionButton.setTitle("Cancel Event", for: .normal)
            actionButton.setTitleColor(.black, for: .normal)
            actionButton.tintColor = UIColor(named: "SoftRedColour")

            
        }else { // Not hosting
            if hasJoined{
                actionButton.setTitle("Cancel RSVP", for: .normal)
                actionButton.setTitleColor(.black, for: .normal)
                actionButton.tintColor = UIColor(named: "LightVioletColour")
            }
            else{
                actionButton.setTitle("I'll Be There!", for: .normal)
                actionButton.setTitleColor(.black, for: .normal)
                actionButton.tintColor = UIColor(named: "SageColor")
            }

        }

        eventNameLabel.text = event.name ?? "Untitled Event"
        
        descriptionLabel.text = event.about ?? "No description provided"
        
        //Format date to string
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
        
        locationLabel.text = event.address ?? "Location to be confirmed"
        capacityLabel.text = "Capacity: \(event.capacity ?? 0)"
        hostLabel.text = "Loading..."
        Task {
            let name = await databaseController?.fetchUserName(uid: event.host ?? "")
            hostLabel.text = name ?? "Unknown"
        }
        
        // Check if the event has lat and lng
        guard let lat = event.latitude, let lng = event.longitude else {
            print("Coordinates not found")
            return
        }

        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let address = event.address ?? "Event"
        
        self.focusMap(address: address, coordinates: coordinate, on: self.mapView)
        
    }
    
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
    
    //MARK: - Action Button Configuration
    
    @IBAction func didTapActionButton(_ sender: Any) {
        
        if isHosting{
            confirmCancelEvent()
           
        }else{
            if hasJoined{
                cancelRsvp()
            }else{
                rsvpEvent()
            }
        }
    }
    
    func confirmCancelEvent(){
        guard let event = event else { return }
        let alert = UIAlertController(
            title: "Cancel Event",
            message: "Are you sure you want to cancel this event?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { _ in
            
            self.databaseController?.deleteEvent(event: event)
            self.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(alert, animated: true)
                        
    
    }
    
    func rsvpEvent(){
        if hasJoined{
            displayMessage(title: "Event already joined.", message: "You have already RSVP'd to this event.")
            return
        }
        guard let event = event else { return }

        Task{
            // Get the UserEvents object for this user, if theres none associated to this user, create a new UserEvents object
            var currentUserEvents = await self.databaseController?.getUserEvents()
            if currentUserEvents == nil{
                currentUserEvents =  self.databaseController?.addUserEvents()
            }
            
            if let currentUserEvents = currentUserEvents{
                let success = self.databaseController?.addEventToUserEvents(event: event, userEvents: currentUserEvents)
                
                if let success = success {
                    displayMessage(title:"Event RSVP'd", message: "You've RSVP'd to \(event.name ?? "this event")!!"){
                        
                        // Update button UI
                        self.actionButton.setTitle("Cancel RSVP", for: .normal)
                        self.actionButton.setTitleColor(.black, for: .normal)
                        self.actionButton.tintColor = UIColor(named: "LightVioletColour")
                        
                        // Go back to events screen
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                }else{
                    displayMessage(title: "Unable to RSVP", message: "Unable to join this event. Please try again another time.")
                }
                
            }
        }
    }
    
    func cancelRsvp(){
        guard let event = event else { return }
        
        Task{
            // Retrieve UserEvents object for this user before removing the event from it.
            let currentUserEvents = await self.databaseController?.getUserEvents()
            guard let currentUserEvents = currentUserEvents else { return }

            let alert = UIAlertController(
                title: "Cancel RSVP?",
                message: "Are you sure you want to cancel your RSVP? You can join the event again later.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { _ in
                let remove = self.databaseController?.removeEventFromUserEvents(event: event, userEvents: currentUserEvents)
                if (remove != nil) {
                    self.actionButton.setTitle("I'll Be There!", for: .normal)
                    self.actionButton.setTitleColor(.black, for: .normal)
                    self.actionButton.tintColor = UIColor(named: "SageColor")
                    
                    // Go back to events screen
                    self.navigationController?.popViewController(animated: true)

                }
            })
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel))
            present(alert, animated: true)
        }
        
    }
    
    // MARK: - Map Functions
        
    // Configure the map view to focus on the region of the event location
    func focusMap( address: String, coordinates: CLLocationCoordinate2D, on mapView: MKMapView){
        
        // Create annotation and configure it
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        
        //Add Title
        annotation.title = address
        
        //Add the annotation to the map
        mapView.addAnnotation(annotation)
        
        mapView.selectAnnotation(annotation, animated: true)
        
        let zoomRegion = MKCoordinateRegion(center: annotation.coordinate,
        latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(zoomRegion, animated: true)
    }
    
    func displayMessage(title:String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message,
         preferredStyle: .alert)
         alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { _ in
            completion?()
         })
        self.present(alertController, animated: true)
//            self.present(alertController, animated: true, completion: nil)
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
